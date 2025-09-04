// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "lib/forge-std/src/Script.sol";
import {TestNFT} from "../src/dev/TestNFT.sol";
import {OzRegistry} from "../src/dev/OzRegistry.sol";
import {S4} from "../src/S4.sol";
import {SolveContract} from "../src/SolveContract.sol";

/**
 * @title LocalAnvil
 * @author kode-n-rolla
 * @notice End-to-end local script for Anvil that deploys:
 *         - TestNFT (ERC-721 reward),
 *         - OzRegistry (ICTFRegistry test stub),
 *         - S4 (challenge),
 *         - SolveContract (attacker),
 *         triggers the exploit, and sweeps the NFT to the EOA.
 * @dev Uses `vm.startBroadcast()`; provide the private key via the CLI flag:
 *      `--private-key 0x<anvil_pk>`
 *      If you enable the registry's source verification (comment inside), call
 *      `reg.addChallenge(address(s4));` before running the exploit.
 */
contract LocalAnvil is Script {
    /**
     * @notice Deploys the test stack, runs the two-step solve in a single tx,
     *         then transfers the reward NFT to the broadcasting EOA.
     */
    function run() external {
        vm.startBroadcast();

        // 1) Deploy the local infra: NFT -> Registry -> S4
        TestNFT nft = new TestNFT();
        OzRegistry reg = new OzRegistry(nft);
        S4 s4 = new S4(address(reg));

        // If you enforce registry source checks in mintNft, uncomment:
        // reg.addChallenge(address(s4));

        // 2) Deploy the attacker contract
        SolveContract attacker = new SolveContract(address(s4));

        console2.log("TestNFT     :", address(nft));
        console2.log("Registry    :", address(reg));
        console2.log("S4          :", address(s4));
        console2.log("SolveContract:", address(attacker));

        // 3) Kick off the exploit (both entries happen within this tx)
        attacker.solvingChallenge();

        // 4) Verify: token #1 should be owned by the attacker
        address owner1 = nft.ownerOf(1);
        console2.log("Owner after mint :", owner1);

        // 5) Sweep the token to the EOA that started the broadcast
        attacker.sweep721(address(nft), 1);

        address owner2 = nft.ownerOf(1);
        console2.log("Owner after sweep:", owner2);

        vm.stopBroadcast();
    }
}
