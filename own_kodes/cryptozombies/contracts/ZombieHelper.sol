// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./ZombieFeeding.sol";

/**
 * @title ZombieHelper (CryptoZombies practice)
 * @author kode-n-rolla
 * @notice Helper utilities: leveling, renaming, DNA tweaks, owner queries.
 * @dev Uses ETH fee for leveling; exposes a view that scans owner’s zombies.
 */
contract ZombieHelper is ZombieFeeding {
    // -----------------------------------------------------------------------
    // Config
    // -----------------------------------------------------------------------

    /// @notice Fee required to level up a zombie (in wei)
    uint256 public levelUpFee = 0.001 ether;

    // -----------------------------------------------------------------------
    // Events
    // -----------------------------------------------------------------------

    /// @notice Emitted when levelUpFee is updated
    event LevelUpFeeUpdated(uint256 newFee);

    /// @notice Emitted when contract balance is withdrawn
    event Withdrawn(address indexed to, uint256 amount);

    /// @notice Emitted when a zombie's name is changed
    event NameChanged(uint256 indexed zombieId, string newName);

    /// @notice Emitted when a zombie's DNA is changed
    event DnaChanged(uint256 indexed zombieId, uint256 newDna);

    /// @notice Emitted when a zombie's level increases
    event LevelIncreased(uint256 indexed zombieId, uint32 newLevel);

    // -----------------------------------------------------------------------
    // Modifiers
    // -----------------------------------------------------------------------

    /**
     * @notice Require zombie to be at or above a certain level
     * @param _level Required level
     * @param _zombieId Target zombie id
     */
    modifier aboveLevel(uint32 _level, uint256 _zombieId) {
        require(_zombieId < zombies.length, "Invalid zombieId");
        require(zombies[_zombieId].level >= _level, "Level too low");
        _;
    }

    // -----------------------------------------------------------------------
    // Admin
    // -----------------------------------------------------------------------

    /**
     * @notice Withdraw all ETH to the contract owner
     * @dev Uses call-pattern instead of transfer to avoid 2300 gas stipend issues
     */
    function withdraw() external onlyOwner {
        address payable to = payable(owner());
        uint256 amount = address(this).balance;
        (bool ok, ) = to.call{value: amount}("");
        require(ok, "Withdraw failed");
        emit Withdrawn(to, amount);
    }

    /**
     * @notice Update the leveling fee
     * @param _fee New fee in wei
     */
    function setLevelUpFee(uint256 _fee) external onlyOwner {
        levelUpFee = _fee;
        emit LevelUpFeeUpdated(_fee);
    }

    // -----------------------------------------------------------------------
    // Leveling
    // -----------------------------------------------------------------------

    /**
     * @notice Pay the fee to level up a zombie by +1
     * @param _zombieId Target zombie id
     */
    function levelUp(uint256 _zombieId) external payable {
        require(msg.value == levelUpFee, "Incorrect fee");
        require(_zombieId < zombies.length, "Invalid zombieId");

        Zombie storage z = zombies[_zombieId];
        unchecked {
            z.level = z.level + 1;
        }
        emit LevelIncreased(_zombieId, z.level);
    }

    // -----------------------------------------------------------------------
    // Mutations (owner-only per zombie)
    // -----------------------------------------------------------------------

    /**
     * @notice Change zombie name; requires level >= 2 and ownership
     * @param _zombieId Target zombie id
     * @param _newName New name
     */
    function changeName(
        uint256 _zombieId,
        string calldata _newName
    ) external aboveLevel(2, _zombieId) onlyOwnerOf(_zombieId) {
        zombies[_zombieId].name = _newName;
        emit NameChanged(_zombieId, _newName);
    }

    /**
     * @notice Change zombie DNA; requires level >= 20 and ownership
     * @dev Ensures DNA is within DNA_MODULUS
     * @param _zombieId Target zombie id
     * @param _newDna New DNA (will be reduced modulo DNA_MODULUS)
     */
    function changeDna(
        uint256 _zombieId,
        uint256 _newDna
    ) external aboveLevel(20, _zombieId) onlyOwnerOf(_zombieId) {
        zombies[_zombieId].dna = _newDna % DNA_MODULUS;
        emit DnaChanged(_zombieId, zombies[_zombieId].dna);
    }

    // -----------------------------------------------------------------------
    // Views
    // -----------------------------------------------------------------------

    /**
     * @notice Returns all zombie IDs owned by `_owner`
     * @dev O(n) over the zombies array; intended for off-chain calls
     * @param _owner Address to scan
     * @return result Array of zombie IDs
     */
    function getZombiesByOwner(address _owner) external view returns (uint256[] memory result) {
        uint256 count = ownerZombieCount[_owner];
        result = new uint256[](count);
        uint256 counter = 0;

        for (uint256 i = 0; i < zombies.length; i++) {
            if (zombieToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
                if (counter == count) break; // small gas/save on long arrays
            }
        }
    }

    // -----------------------------------------------------------------------
    // Receive ETH
    // -----------------------------------------------------------------------

    /// @notice Allow the contract to receive ETH (e.g., levelUp fees)
    receive() external payable {}
}
