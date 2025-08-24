// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/12-LessonHelper.sol";

/**
 * @title FuzzHellFuncTest
 * @author kode-n-rolla
 * @notice Property-based (fuzz) test that searches for a `uint128` input causing `LessonTwelveHelper.hellFunc` to revert.
 * @dev
    - The helper is deployed fresh in `setUp()`.
    - The fuzz test feeds random `uint128` values into `hellFunc`.
    - On the first revert caught via `try/catch`, the test logs and writes the input to `./result.json`.
    - This file is meant as a standalone exploration tool; it does not solve the full challenge by itself.
*/

contract FuzzHellFuncTest is Test {
    /// @notice The helper contract under test (created by this test).
    LessonTwelveHelper helper;

    /// @notice Deploy a fresh helper instance for each test run.
    function setUp() public {
        helper = new LessonTwelveHelper();
    }

    /**
     * @notice Fuzzing entrypoint: Foundry will generate many `number` values automatically.
     * @dev
        - If `hellFunc(number)` returns normally, we do nothing (fuzzer continues with other inputs).
        - If it reverts, we log the number, serialize it to JSON, and mark the test as passed.
     * @param number A randomized 128-bit candidate input for `hellFunc`.
     */
    function testFuzz_FindRevertingNumber(uint128 number) public {
        // We explicitly call without prank: here msg.sender is the test contract,
        // which is fine for pure discovery of reverting inputs.
        try helper.hellFunc(number) returns (uint256 /* result */) {
            // No revert: let the fuzzer continue with more inputs.
            return;
        } catch {
            // Revert observed: record and persist the candidate.

            // Human-readable logs
            console2.log("SUCCESS: Number causes revert");
            console2.log("Reverting number:", uint256(number));
            emit log_named_uint("Reverting number", number);

            // Persist to JSON for later use (e.g., scripts / other tests)
            // Note: the returned string of the LAST serialize* call contains the full JSON for this object label.
            string memory obj = "result";
            vm.serializeUint(obj, "revertingNumber", number);
            string memory json = vm.serializeString(obj, "twitter", "@your_twitter");
            vm.writeJson(json, "./result.json");

            // Mark this fuzz case as a success.
            assertTrue(true);
        }
    }
}
