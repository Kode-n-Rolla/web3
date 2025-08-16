// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * @title ILessonNine - Interface for LessonNine challenge
 * @author kode-n-rolla
 * @notice This interface allows solving the LessonNine challenge by submitting a guess and a Twitter handle
 */

interface ILessonNine {
    /// @notice Submit your solution to the challenge
    /// @param randomGuess The guessed number to solve the challenge
    /// @param yourTwitterHandle Your Twitter handle to be displayed on the leaderboard
    function solveChallenge(uint256 randomGuess, string calldata yourTwitterHandle) external;
}
