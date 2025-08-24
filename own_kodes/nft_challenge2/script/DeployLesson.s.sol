// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/12-Lesson.sol";

/*
 * @title DeployLesson
 * @author kode-n-rolla
 * @notice Broadcast script to deploy LessonTwelve on a target network.
 * @dev
 * - Reads the deployer's private key from env var `PRIVATE_KEY`.
 * - Reads the FCN (Foundry Course/NFT registry) contract address from env var `FCN_ADDRESS`.
 *   This must be a *contract* implementing whatever interface AFoundryCourseChallenge expects
 *   (e.g., a `mintNft(address,string)` function), otherwise `solveChallenge` may revert later.
 * - Example:
 *     PRIVATE_KEY=0x... FCN_ADDRESS=0xYourFcnContract forge script script/DeployLesson.s.sol:DeployLesson --rpc-url $RPC --broadcast
 */
contract DeployLesson is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address fcnAddress = vm.envAddress("FCN_ADDRESS"); // Must be a contract address

        vm.startBroadcast(deployerPrivateKey);

        LessonTwelve lesson = new LessonTwelve(fcnAddress);

        console2.log("LessonTwelve deployed at:", address(lesson));
        console2.log("Hell contract address:", lesson.getHellContract());

        vm.stopBroadcast();
    }
}
