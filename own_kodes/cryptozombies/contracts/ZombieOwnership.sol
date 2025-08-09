// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "./ZombieAttack.sol";
import "./ERC721.sol";

/**
 * @title ZombieOwnership (CryptoZombies practice)
 * @author kode-n-rolla
 * @notice Minimal ERC-721-like ownership layer for Zombies.
 * @dev Educational only; not fully ERC-721 compliant (no safeTransferFrom, no operator approvals).
 *      Consider migrating to OpenZeppelin ERC721 for real projects.
 */
contract ZombieOwnership is ZombieAttack, ERC721 {
    // -----------------------------------------------------------------------
    // Approvals
    // -----------------------------------------------------------------------

    /// @notice Approved address per tokenId
    mapping(uint256 => address) private zombieApprovals;

    // -----------------------------------------------------------------------
    // ERC721 (minimal subset)
    // -----------------------------------------------------------------------

    /**
     * @inheritdoc ERC721
     */
    function balanceOf(address _owner) external view override returns (uint256) {
        require(_owner != address(0), "Zero address");
        return ownerZombieCount[_owner];
    }

    /**
     * @inheritdoc ERC721
     */
    function ownerOf(uint256 _tokenId) public view override returns (address) {
        require(_exists(_tokenId), "Nonexistent token");
        return zombieToOwner[_tokenId];
    }

    /**
     * @notice Returns the approved address for a tokenId
     * @dev Not in some minimal interfaces, but useful for tooling
     */
    function getApproved(uint256 _tokenId) external view returns (address) {
        require(_exists(_tokenId), "Nonexistent token");
        return zombieApprovals[_tokenId];
    }

    /**
     * @inheritdoc ERC721
     */
    function approve(address _approved, uint256 _tokenId) external payable override onlyOwnerOf(_tokenId) {
        require(_approved != ownerOf(_tokenId), "Approve to owner");
        zombieApprovals[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    /**
     * @inheritdoc ERC721
     */
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable override {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not approved nor owner");
        _transfer(_from, _to, _tokenId);
    }

    // -----------------------------------------------------------------------
    // Internal helpers
    // -----------------------------------------------------------------------

    /// @dev Returns true if tokenId exists
    function _exists(uint256 _tokenId) internal view returns (bool) {
        return _tokenId < zombies.length && zombieToOwner[_tokenId] != address(0);
    }

    /// @dev Returns true if `spender` is owner or approved for `_tokenId`
    function _isApprovedOrOwner(address spender, uint256 _tokenId) internal view returns (bool) {
        address owner_ = ownerOf(_tokenId);
        return (spender == owner_ || zombieApprovals[_tokenId] == spender);
    }

    /**
     * @dev Core transfer logic: updates owner mappings, clears approval, emits Transfer.
     *      No ERC721Receiver check here (not a safe transfer).
     */
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        require(_to != address(0), "Transfer to zero");
        require(ownerOf(_tokenId) == _from, "From is not owner");

        // Clear any prior approval
        if (zombieApprovals[_tokenId] != address(0)) {
            delete zombieApprovals[_tokenId];
        }

        // Update balances
        unchecked {
            ownerZombieCount[_to] += 1;
            ownerZombieCount[_from] -= 1;
        }

        // Update owner
        zombieToOwner[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);
    }
}
