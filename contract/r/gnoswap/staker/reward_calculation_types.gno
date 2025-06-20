package staker

import (
	"strconv"
	"strings"

	"gno.land/p/demo/avl"
)

// EncodeUint converts a uint64 number into a zero-padded 20-character string.
//
// Parameters:
// - num (uint64): The number to encode.
//
// Returns:
// - string: A zero-padded string representation of the number.
//
// Example:
// Input: 12345
// Output: "00000000000000012345"
func EncodeUint(num uint64) string {
	// Convert the value to a decimal string.
	s := strconv.FormatUint(num, 10)

	// Zero-pad to a total length of 20 characters.
	zerosNeeded := 20 - len(s)
	return strings.Repeat("0", zerosNeeded) + s
}

func EncodeInt64(num int64) string {
	s := strconv.FormatInt(num, 10)
	zerosNeeded := 20 - len(s)
	return strings.Repeat("0", zerosNeeded) + s
}

// DecodeUint converts a zero-padded string back into a uint64 number.
//
// Parameters:
// - s (string): The zero-padded string.
//
// Returns:
// - uint64: The decoded number.
//
// Panics:
// - If the string cannot be parsed into a uint64.
//
// Example:
// Input: "00000000000000012345"
// Output: 12345
func DecodeUint(s string) uint64 {
	num, err := strconv.ParseUint(s, 10, 64)
	if err != nil {
		panic(err)
	}
	return num
}

func DecodeInt64(s string) int64 {
	num, err := strconv.ParseInt(s, 10, 64)
	if err != nil {
		panic(err)
	}
	return num
}

// UintTree is a wrapper around an AVL tree for storing block heights as strings.
// Since block heights are defined as int64, we take int64 and convert it to uint64 for the tree.
//
// Methods:
// - Get: Retrieves a value associated with a uint64 key.
// - set: Stores a value with a uint64 key.
// - Has: Checks if a uint64 key exists in the tree.
// - remove: Removes a uint64 key and its associated value.
// - Iterate: Iterates over keys and values in a range.
// - ReverseIterate: Iterates in reverse order over keys and values in a range.
type UintTree struct {
	tree *avl.Tree // blockNumber -> any
}

// NewUintTree creates a new UintTree instance.
func NewUintTree() *UintTree {
	return &UintTree{
		tree: avl.NewTree(),
	}
}

func (self *UintTree) Get(key int64) (any, bool) {
	v, ok := self.tree.Get(EncodeInt64(key))
	if !ok {
		return nil, false
	}
	return v, true
}

func (self *UintTree) set(key int64, value any) {
	self.tree.Set(EncodeInt64(key), value)
}

func (self *UintTree) Has(key int64) bool {
	return self.tree.Has(EncodeInt64(key))
}

func (self *UintTree) remove(key int64) {
	self.tree.Remove(EncodeInt64(key))
}

func (self *UintTree) Iterate(start, end int64, fn func(key int64, value any) bool) {
	self.tree.Iterate(EncodeInt64(start), EncodeInt64(end), func(key string, value any) bool {
		return fn(DecodeInt64(key), value)
	})
}

func (self *UintTree) ReverseIterate(start, end int64, fn func(key int64, value any) bool) {
	self.tree.ReverseIterate(EncodeInt64(start), EncodeInt64(end), func(key string, value any) bool {
		return fn(DecodeInt64(key), value)
	})
}
