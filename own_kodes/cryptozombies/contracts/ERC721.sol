// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

/**
 * @title Minimal ERC-721 interface (course-compatible)
 * @author kode-n-rolla
 * @notice Minimal subset needed by the CryptoZombies practice contracts.
 * @dev Educational only. Not a full ERC-721 implementation.
 */
interface ERC721 {
    /// @notice Emitted when ownership of any NFT changes by any mechanism
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @notice Emitted when the approved address for an NFT is changed or reaffirmed
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /**
     * @notice Count all NFTs assigned to an owner
     * @param _owner Address to query
     * @return balance Owner's NFT count
     */
    function balanceOf(address _owner) external view returns (uint256 balance);

    /**
     * @notice Find the owner of an NFT
     * @param _tokenId The identifier for an NFT
     * @return owner Owner address
     */
    function ownerOf(uint256 _tokenId) external view returns (address owner);

    /**
     * @notice Transfer ownership of an NFT
     * @dev Course version keeps it payable for simplicity
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     */
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /**
     * @notice Change or reaffirm the approved address for an NFT
     * @dev Course version keeps it payable for simplicity
     * @param _approved The new approved NFT controller
     * @param _tokenId The NFT to approve
     */
    function approve(address _approved, uint256 _tokenId) external payable;
}
