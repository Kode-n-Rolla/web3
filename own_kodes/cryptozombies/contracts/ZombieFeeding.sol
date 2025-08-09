// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./ZombieFactory.sol";

/// @notice Minimal interface for CryptoKitties getKitty
interface KittyInterface {
    function getKitty(uint256 _id)
        external
        view
        returns (
            bool isGestating,
            bool isReady,
            uint256 cooldownIndex,
            uint256 nextActionAt,
            uint256 siringWithId,
            uint256 birthTime,
            uint256 matronId,
            uint256 sireId,
            uint256 generation,
            uint256 genes
        );
}

/**
 * @title ZombieFeeding (CryptoZombies practice)
 * @author kode-n-rolla
 * @notice Feeding mechanics for zombies; can consume external DNA such as CryptoKitties genes.
 * @dev Inherits storage and helpers from {ZombieFactory}. Cooldowns are time-based; DNA mixing is simplistic.
 */
contract ZombieFeeding is ZombieFactory {
    /// @dev External dependency (e.g., CryptoKitties core contract)
    KittyInterface public kittyContract;

    // -----------------------------------------------------------------------
    // Modifiers
    // -----------------------------------------------------------------------

    /// @notice Restricts actions to the owner of a specific zombie
    /// @param _zombieId Target zombie id
    modifier onlyOwnerOf(uint256 _zombieId) {
        require(msg.sender == zombieToOwner[_zombieId], "Not the zombie owner");
        _;
    }

    // -----------------------------------------------------------------------
    // Admin
    // -----------------------------------------------------------------------

    /**
     * @notice Set the external CryptoKitties contract address
     * @dev Callable by contract owner only
     * @param _address Address of the Kitty contract
     */
    function setKittyContractAddress(address _address) external onlyOwner {
        require(_address != address(0), "Zero address");
        kittyContract = KittyInterface(_address);
    }

    // -----------------------------------------------------------------------
    // Internal cooldown helpers
    // -----------------------------------------------------------------------

    /**
     * @notice Starts the cooldown timer for a zombie
     * @param _zombie Storage reference to the zombie
     */
    function _triggerCooldown(Zombie storage _zombie) internal {
        _zombie.readyTime = uint32(block.timestamp + COOLDOWN_TIME);
    }

    /**
     * @notice Checks if a zombie is ready (cooldown passed)
     * @param _zombie Storage reference to the zombie
     * @return ready True if cooldown has elapsed
     */
    function _isReady(Zombie storage _zombie) internal view returns (bool ready) {
        ready = (_zombie.readyTime <= block.timestamp);
    }

    // -----------------------------------------------------------------------
    // Feeding / DNA mixing
    // -----------------------------------------------------------------------

    /**
     * @notice Mixes zombie DNA with a target DNA and creates a new zombie
     * @dev Rounds target DNA by DNA modulus; if species == "kitty", adjust tail to 99
     * @param _zombieId The feeder zombie id (must be owned by caller)
     * @param _targetDna The external DNA to mix with
     * @param _species Species label (e.g., "kitty")
     */
    function feedAndMultiply(
        uint256 _zombieId,
        uint256 _targetDna,
        string memory _species
    ) internal onlyOwnerOf(_zombieId) {
        require(_zombieId < zombies.length, "Invalid zombieId");

        Zombie storage myZombie = zombies[_zombieId];
        require(_isReady(myZombie), "Zombie on cooldown");

        _targetDna = _targetDna % DNA_MODULUS;

        uint256 newDna = (myZombie.dna + _targetDna) / 2;

        // Species-specific tweak: set the last two digits to 99 for kitties
        if (keccak256(abi.encodePacked(_species)) == keccak256(abi.encodePacked("kitty"))) {
            newDna = newDna - (newDna % 100) + 99;
        }

        _createZombie("NoName", newDna);
        _triggerCooldown(myZombie);
    }

    /**
     * @notice Feeds a zombie on a CryptoKitty by kittyId
     * @param _zombieId The feeder zombie id
     * @param _kittyId CryptoKitty id to fetch genes from
     */
    function feedOnKitty(uint256 _zombieId, uint256 _kittyId) external {
        // Pull only the 'genes' field from getKitty
        (,,,,,,,,, uint256 kittyGenes) = kittyContract.getKitty(_kittyId);
        feedAndMultiply(_zombieId, kittyGenes, "kitty");
    }
}
