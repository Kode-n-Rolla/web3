// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/12-Lesson.sol";
import "../src/SolverContract.sol";

/*
 * @title SolveWith99
 * @author kode-n-rolla
 * @notice Broadcast script that solves LessonTwelve using a known reverting number (99).
 * @dev
 * - Reads `ATTACKER_PRIVATE_KEY` and `LESSON_ADDRESS` from environment variables.
 * - Deploys a minimal solver card (SolverContract) owned by the attacker EOA and
 *   returning the chosen number via `getNumberr()`.
 * - Calls `solveChallenge(solver, "@your_twitter")` from the attacker's EOA.
 * - If the FCN registry passed to LessonTwelve at deployment is not a contract,
 *   the solve will likely revert when Lesson tries to mint/record the result.
 *
 * Example:
 *   ATTACKER_PRIVATE_KEY=0x... LESSON_ADDRESS=0xLesson forge script script/SolveWith99.s.sol:SolveWith99 --rpc-url $RPC --broadcast
 */
contract SolveWith99 is Script {
    // Replace with your discovered reverting number if different
    uint128 internal constant REVERTING_NUMBER = 99;

    function run() external {
        uint256 attackerPrivateKey = vm.envUint("ATTACKER_PRIVATE_KEY");
        address lessonAddress = vm.envAddress("LESSON_ADDRESS");

        vm.startBroadcast(attackerPrivateKey);

        address attacker = vm.addr(attackerPrivateKey);

        // Deploy the solver card owned by the attacker EOA with the reverting number.
        SolverContract solver = new SolverContract(attacker, REVERTING_NUMBER);

        console2.log("Attacker:", attacker);
        console2.log("Solver contract:", address(solver));
        console2.log("Using number:", uint256(REVERTING_NUMBER));

        // Solve the challenge. Twitter handle can be empty or customized.
        LessonTwelve(lessonAddress).solveChallenge(address(solver), "@your_twitter");

        console2.log("Challenge solved!");

        vm.stopBroadcast();
    }
}
