// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ICTFRegistry} from "../ICTFRegistry.sol";
import {TestNFT} from "./TestNFT.sol";

/**
 * @title OzRegistry (Test Stub)
 * @author kode-n-rolla
 * @notice Minimal test implementation of the ICTFRegistry used for local/E2E testing.
 * @dev Matches ICTFRegistry signatures exactly (including `memory` and return types).
 *      Optionally restricts minters to registered challenge contracts via `isChallenge`.
 */
contract OzRegistry is ICTFRegistry {
    /// @notice ERC-721 collection used to mint rewards in tests.
    TestNFT public immutable nft;

    /// @notice Optional allowlist of challenge contracts permitted to mint.
    mapping(address => bool) public isChallenge;

    /**
     * @param _nft Address of the ERC-721 reward contract.
     */
    constructor(TestNFT _nft) {
        nft = _nft;
    }

    /**
     * @inheritdoc ICTFRegistry
     * @dev Registers a challenge contract (for optional source validation).
     * @param challengeContract Address of the challenge to allow.
     * @return The same `challengeContract` address (per interface).
     */
    function addChallenge(address challengeContract)
        external
        override
        returns (address)
    {
        isChallenge[challengeContract] = true;
        return challengeContract;
    }

    /**
     * @inheritdoc ICTFRegistry
     * @dev Mints a reward NFT to `receiver`. The `twitterHandle` is accepted to match
     *      the interface but is unused in this test stub.
     *      Uncomment the `require` below to enforce registration of `msg.sender`.
     * @param receiver The address receiving the newly minted NFT.
     * @param /* twitterHandle */ Ignored in this test implementation.
     * @return tokenId The newly minted token ID.
     */
    function mintNft(address receiver, string memory /* twitterHandle */)
        external
        override
        returns (uint256 tokenId)
    {
        // require(isChallenge[msg.sender], "CTFRegistry__NotChallengeContract()");
        tokenId = nft.mint(receiver);
    }
}
