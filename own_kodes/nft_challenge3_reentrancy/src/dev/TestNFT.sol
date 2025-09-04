// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

/**
 * @title TestNFT
 * @author kode-n-rolla
 * @notice Minimal ERC-721 used for local/E2E tests. Uses safe minting.
 * @dev `_safeMint` triggers `onERC721Received` on contracts, so the attacker
 *      must implement `IERC721Receiver` for mints to succeed.
 */
contract TestNFT is ERC721 {
    /// @notice Next token ID to be minted.
    uint256 public nextId;

    constructor() ERC721("CTF Reward", "CTFR") {}

    /**
     * @notice Mints a new token to `to` using `_safeMint`.
     * @param to Recipient of the new token.
     * @return id The newly minted token ID.
     */
    function mint(address to) external returns (uint256 id) {
        id = ++nextId;
        _safeMint(to, id);
    }
}
