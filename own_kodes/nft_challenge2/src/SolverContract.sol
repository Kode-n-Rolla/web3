// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title SolverContract
 * @author kode-n-rolla
 * @notice Minimal “solver card” contract used by the LessonTwelve challenge.
 * @dev
  LessonTwelve expects the exploit/solver contract to expose two view functions:
    - `getOwner() -> address`
    - `getNumberr() -> uint128`
  Both values are set once in the constructor and stored as immutables. During
  `solveChallenge`, LessonTwelve checks that `msg.sender == getOwner()` and then
  forwards `getNumberr()` to its helper’s `hellFunc(uint128)`.
*/

contract SolverContract {
    /// @notice EOA expected to call `solveChallenge` in LessonTwelve.
    address private immutable i_owner;
    
    /// @notice Candidate number that LessonTwelve forwards to `hellFunc(uint128)`.
    uint128 private immutable i_number;

    /// @param owner_ The solver EOA; LessonTwelve requires `msg.sender == getOwner()`.
    /// @param number_ The number candidate to be consumed by the challenge.

  construct(address _ownerm uint128 _number)  {
    i_owner = _owner;
    i_number = _number;
  }

    /// @notice Returns the solver EOA recorded at construction.
    /// @return The address that must call `solveChallenge`.
    function getOwner() external view returns (address) {
        return i_owner;
    }

    /// @notice Returns the candidate number recorded at construction.
    /// @return The `uint128` value to be used by the challenge.
    function getNumberr() external view returns (uint128) {
        return i_number;
    }
}    
  
