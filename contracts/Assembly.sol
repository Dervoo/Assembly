// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Assembly {
    uint256 private value;
    mapping(address => uint256) public numbers;
    bytes32 public hash;

    /// Solidity Part

    function returnValueSOL() external view returns (uint256) {
        return value;
    }

    function setNewValueSOL(uint256 number) external {
        value = number;
    }

    function addNumberSOL(uint256 _number) external {
        numbers[msg.sender] = _number;
    }

    function addNumbersListSOL(
        address[] memory _users,
        uint256[] memory _numbers
    ) external {
        for (uint256 i = 0; i < _users.length; i++) {
            numbers[_users[i]] = _numbers[i];
        }
    }

    function hashStringSOL(string memory _string) external {
        hash = keccak256(abi.encodePacked(_string));
    }

    /// #dev Assembly Part

    function returnValueASS() external view returns (uint256) {
        /// @dev 0x00 & 0x20 - values can be stored as anything, then can be overwritten everytime
        assembly {
            /// @dev variable.slot gives value of variable
            let _value := sload(0)
            let ptr := mload(0x40)
            /// @dev we write to address in memory (free space)
            mstore(ptr, _value)
            /// @dev mstore (where, what)
            return(ptr, 0x20)
            /// @dev ptr is address where value is stored, 0x20 means 32 bytes, 0x40 means 64 bytes
        }
    }

    function setNewValueASS(uint256 _number) external {
        assembly {
            /// @dev variable.slot gives value of variable
            let slot := value.slot
            sstore(slot, _number)
            /// @dev we change variable slot from last value to the newest value
        }
    }

    function addNumberASS(uint256 _numberAdded) external {
        assembly {
            /// @dev set the slot where we will store the value
            let ptr := mload(0x40)
            /// @dev set ptr as msg.sender, caller() -> returns msg.sender Solidity alike
            mstore(ptr, caller())

            /// @dev store the slot number for `numbers`
            mstore(add(ptr, 0x20), numbers.slot)
            /// @dev numbers are 2 previous and current, they change into 2x 32 bytes -> 0x40
            let slot := keccak256(ptr, 0x40)
            /// @dev store value
            sstore(slot, _numberAdded)
        }
    }

    function hashStringASS(string memory _string)
        external
        pure
        returns (bytes32)
    {
        assembly {
            /// @dev _string represents the address in memory where the data for our string starts
            /// @dev at `_string` we have the length of the string
            /// @dev at `_string` + 32 -> we have the string itself
            let strSize := mload(_string)
            /// @dev we add 32 to that address, so that we have the address of the string itself
            let strAddr := add(_string, 32)
            /// @dev we then pass the address of the string, and its size. This will hash our string
            let _hash := keccak256(strAddr, strSize)
            /// @dev we store the hash value at slot 0 in memory
            /// @dev 0 slot is cheaper than 0x40
            mstore(0, _hash)
            /// @dev return what is stored at slot 0 (our hash) and the length of the hash (32)
            return(0, 32)
        }
    }

    function addMultipleNumbersASS(
        address[] memory _users,
        uint256[] memory _numbers
    ) external {
        assembly {
            /// @dev`_users` is the address in memory where the parameter starts and its size
            let usersSize := mload(_users)
            /// @dev same for `_numbers`
            let numbersSize := mload(_numbers)

            /// @dev we check that both arrays are the same size
            /// @dev if eq() returns 1 they are equal, if 0 then they are not and we revert
            if iszero(eq(usersSize, numbersSize)) {
                revert(0, 0)
            }

            /// @dev we use a for-loop to loop through the items
            /// @dev 1 if x < y, 0 otherwise -> lt
            for {
                let i := 0
            } lt(i, usersSize) {
                i := add(i, 1)
            } {
                /// @dev to get the ith value from the array we multiply i by 32 (0x20) and add it to `_users`
                /// @dev we always have to add 1 to i first, because remember that `_users` is the size of the array, the values start 32 bytes after
                /// @dev we could also do it this way (maybe it makes more sense):
                /// @dev let userAddress := mload(add(add(_users, 0x20), mul(0x20, i)))
                let userAddress := mload(add(_users, mul(0x20, add(i, 1))))
                let userBalance := mload(add(_numbers, mul(0x20, add(i, 1))))
                /// @dev we use the 0 memory slot as temporary storage to compute our hash
                /// @dev we store the address there
                mstore(0, userAddress)
                /// @dev we store mapping slot
                mstore(0x20, numbers.slot)
                /// @dev the storage slot number
                let slot := keccak256(0, 0x40)
                /// @dev store our value to it
                sstore(slot, userBalance)
                /// @dev 0x00 -> userAddress, 0x20 -> numbers.slot, 0x40 -> userBalance
            }
        }
    }
}
