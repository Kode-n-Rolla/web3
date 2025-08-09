// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

/**
 * @title Ownable (minimal)
 * @author kode-n-rolla
 * @notice Basic access control with a single owner account.
 * @dev Educational, compact version. Sets deployer as the initial owner.
 */
abstract contract Ownable {
    /// @notice Current owner of the contract
    address private _owner;

    /// @notice Emitted when ownership is transferred
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @notice Initializes the contract setting the deployer as the initial owner
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @notice Returns the address of the current owner
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @notice Ensures that the caller is the contract owner
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @notice Leaves the contract without owner. It will not be possible to call
     *         `onlyOwner` functions anymore. Use with care!
     */
    function renounceOwnership() external onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @notice Transfers ownership to a new account (`newOwner`)
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Internal ownership transfer helper
     */
    function _transferOwnership(address newOwner) internal {
        address old = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(old, newOwner);
    }
}
