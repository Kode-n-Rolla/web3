// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/12-Lesson.sol";
import "../src/SolverContract.sol";

/**
 * @title DirectAttack
 * @author kode-n-rolla
 * @notice Broadcast script demonstrating a direct solve flow:
 *         deploy a solver card owned by the attacker EOA and call `solveChallenge`.
 * @dev
 * - Reads `ATTACKER_PRIVATE_KEY` and `LESSON_ADDRESS` from environment variables.
 * - Uses a known reverting number (99) found via fuzzing.
 * - The `getOwner()` of the solver must equal `msg.sender` at `solveChallenge` time.
 * - Ensure the FCN address used at lesson deployment was a contract; otherwise the
 *   post-solve mint/record step may revert.
 *
 * Example:
 *   ATTACKER_PRIVATE_KEY=0x... LESSON_ADDRESS=0xLesson forge script script/DirectAttack.s.sol:DirectAttack --rpc-url $RPC --broadcast
 */
contract DirectAttack is Script {
    uint128 internal constant REVERTING_NUMBER = 99; // Replace if your discovered value differs

    function run() external {
        uint256 attackerPrivateKey = vm.envUint("ATTACKER_PRIVATE_KEY");
        address lessonAddress = vm.envAddress("LESSON_ADDRESS");

        vm.startBroadcast(attackerPrivateKey);

        address attacker = vm.addr(attackerPrivateKey);

        // The critical property: `getOwner()` returns the solver's EOA.
        SolverContract solver = new SolverContract(attacker, REVERTING_NUMBER);

        console2.log("Attacker address:", attacker);
        console2.log("Solver contract:", address(solver));
        console2.log("Using number:", uint256(REVERTING_NUMBER));

        LessonTwelve(lessonAddress).solveChallenge(address(solver), "@your_twitter");

        vm.stopBroadcast();
    }
}
