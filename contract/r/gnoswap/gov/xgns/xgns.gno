package xgns

import (
	"std"
	"strings"

	"gno.land/p/demo/grc/grc20"
	"gno.land/p/demo/ownable"
	"gno.land/p/demo/ufmt"

	"gno.land/r/gnoswap/v1/access"

	"gno.land/r/gnoswap/v1/halt"
)

var (
	admin         = ownable.NewWithAddress(std.DerivePkgAddr(govStakerAddr.String()))
	token, ledger = grc20.NewToken("XGNS", "xGNS", 6)

	govStakerAddr = getContractAddress(access.ROLE_GOV_STAKER)
	launchpadAddr = getContractAddress(access.ROLE_LAUNCHPAD)
)

func init() {}

func TotalSupply() int64 {
	return token.TotalSupply()
}

// VotingSupply calculates the total supply of tokens eligible for voting.
//
// This function determines the total voting supply by subtracting the amount
// of tokens held by the launchpad contract from the total minted token supply.
// Tokens held by the launchpad contract do not participate in voting.
//
// Returns:
// - uint64: The total supply of tokens available for voting.
//
// Notes:
// - `TotalSupply`: Represents the total amount of xGNS tokens minted.
// - `BalanceOf(launchpadAddr)`: Retrieves the amount of xGNS tokens held by the launchpad contract.
func VotingSupply() int64 {
	total := token.TotalSupply() // this is entire amount of xGNS minted

	// this is amount of xGNS held by launchpad
	// this xGNS doesn't participate in voting
	launchpad := token.BalanceOf(launchpadAddr)
	return total - launchpad
}

// BalanceOf retrieves the token balance of a specified address.
//
// This function resolves the provided address or name and queries the token balance
// associated with the resolved address.
//
// Parameters:
// - owner: The address or name of the user whose balance is being queried.
//
// Returns:
// - uint64: The current token balance of the specified address.
func BalanceOf(owner std.Address) int64 {
	return token.BalanceOf(owner)
}

// xGNS is non-transferable
// Therefore it doesn't have transfer and transferFrom functions
func Render(path string) string {
	parts := strings.Split(path, "/")
	c := len(parts)

	switch {
	case path == "":
		return token.RenderHome()
	case c == 2 && parts[0] == "balance":
		balance := token.BalanceOf(std.Address(parts[1]))
		return ufmt.Sprintf("%d\n", balance)
	default:
		return "404\n"
	}
}

// Mint increases the balance of a specified address by a given amount.
//
// This function is restricted to be called only by specific authorized contracts:
// - Governance staker contract
//
// If the caller is not one of these contracts, the function will panic with an error.
//
// Parameters:
// - to: The address or name of the user whose balance will be increased.
// - amount: The amount of tokens to be minted.
//
// Errors:
// - Panics if the caller is unauthorized.
// - Propagates any error from the ledger.Mint function.
func Mint(cur realm, to std.Address, amount int64) {
	currentLevel := halt.GetCurrentHaltLevel()
	if currentLevel != halt.LvMainnetSafeMode {
		// Check if withdrawals are specifically halted, not just if the system is halted
		if err := halt.IsHalted(halt.OpTypeWithdraw); err != nil {
			panic(err.Error())
		}

		if halt.IsContractHalted(halt.OpTypeXGns) {
			panic("xGNS contract operations are currently disabled")
		}
	}

	// only (gov staker) or (launchpad) contract can call Mint
	caller := std.PreviousRealm().Address()

	if govStakerAddr == caller || launchpadAddr == caller {
		checkErr(ledger.Mint(to, amount))
	} else {
		panic(addDetailToError(
			errNoPermission,
			ufmt.Sprintf("only gov/staker(%s) or launchpad(%s) contract can call Mint, called from %s", govStakerAddr.String(), launchpadAddr.String(), caller.String()),
		))
	}
}

// MintByLaunchPad increases the balance of a specified address by a given amount.
//
// This function is restricted to be called only by specific authorized contracts:
// - Launchpad contract
//
// If the caller is not one of these contracts, the function will panic with an error.
//
// Parameters:
// - to: The address or name of the user whose balance will be increased.
// - amount: The amount of tokens to be minted.
//
// Errors:
// - Panics if the caller is unauthorized.
// - Propagates any error from the ledger.Mint function.
func MintByLaunchPad(cur realm, to std.Address, amount int64) {
	currentLevel := halt.GetCurrentHaltLevel()
	if currentLevel != halt.LvMainnetSafeMode {
		// Check if withdrawals are specifically halted, not just if the system is halted
		if err := halt.IsHalted(halt.OpTypeWithdraw); err != nil {
			panic(err.Error())
		}

		if halt.IsContractHalted(halt.OpTypeXGns) {
			panic("xGNS contract operations are currently disabled")
		}
	}

	caller := std.PreviousRealm().Address()
	if err := access.LaunchpadOnly(caller); err != nil {
		panic(addDetailToError(
			errNoPermission,
			ufmt.Sprintf("only launchpad(%s) contract can call MintByLaunchPad, called from %s", launchpadAddr.String(), caller.String()),
		))
	}

	mint(to, amount)
}

// mint increases the balance of a specified address by a given amount.
func mint(to std.Address, amount int64) {
	checkErr(ledger.Mint(to, amount))
}

// Burn reduces the balance of a specified address by a given amount.
//
// This function is restricted to be called only by specific authorized contracts:
// - Governance staker contract
// - Launchpad contract
//
// If the caller is not one of these contracts, the function will panic with an error.
//
// Parameters:
// - from: The address or name of the user whose balance will be reduced.
// - amount: The amount of tokens to be burned.
//
// Errors:
// - Panics if the caller is unauthorized.
// - Propagates any error from the ledger.Burn function.
func Burn(cur realm, from std.Address, amount int64) {
	currentLevel := halt.GetCurrentHaltLevel()
	if currentLevel != halt.LvMainnetSafeMode {
		// Check if withdrawals are specifically halted, not just if the system is halted
		if err := halt.IsHalted(halt.OpTypeWithdraw); err != nil {
			panic(err.Error())
		}

		if halt.IsContractHalted(halt.OpTypeXGns) {
			panic("xGNS contract operations are currently disabled")
		}
	}

	// only (gov staker) or (launchpad) contract can call Mint
	caller := std.PreviousRealm().Address()

	if govStakerAddr == caller || launchpadAddr == caller {
		burn(from, amount)
	} else {
		panic(addDetailToError(
			errNoPermission,
			ufmt.Sprintf("only gov/staker(%s) or launchpad(%s) contract can call Burn, called from %s", govStakerAddr.String(), launchpadAddr.String(), caller.String()),
		))
	}
}

func BurnByLaunchPad(cur realm, from std.Address, amount int64) {
	currentLevel := halt.GetCurrentHaltLevel()
	if currentLevel != halt.LvMainnetSafeMode {
		// Check if withdrawals are specifically halted, not just if the system is halted
		if err := halt.IsHalted(halt.OpTypeWithdraw); err != nil {
			panic(err.Error())
		}

		if halt.IsContractHalted(halt.OpTypeXGns) {
			panic("xGNS contract operations are currently disabled")
		}
	}

	caller := std.PreviousRealm().Address()
	if err := access.LaunchpadOnly(caller); err != nil {
		panic(addDetailToError(
			errNoPermission,
			ufmt.Sprintf("only launchpad(%s) contract can call BurnByLaunchPad, called from %s", launchpadAddr.String(), caller.String()),
		))
	}
	burn(from, amount)
}

func burn(from std.Address, amount int64) {
	checkErr(ledger.Burn(from, amount))
}

// getContractAddress retrieves the address which registered the role
func getContractAddress(roleName string) std.Address {
	addr, _ := access.GetAddress(roleName)
	return addr
}
