// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "./Ownable.sol";

/**
 * @title ZombieFactory (CryptoZombies practice)
 * @author kode-n-rolla
 * @notice Simple factory that mints the first zombie for each address.
 * @dev Uses pseudo-random DNA based on keccak256 — predictable and NOT for production.
 */
contract ZombieFactory is Ownable {
    /// @notice Emitted when a new zombie is created
    /// @param zombieId Index of the zombie in the array
    /// @param owner Owner address of the zombie
    /// @param name Zombie name
    /// @param dna 16-digit DNA value
    event NewZombie(uint256 indexed zombieId, address indexed owner, string name, uint256 dna);

    // --- Constants -----------------------------------------------------------

    uint256 private constant DNA_DIGITS = 16;
    uint256 internal constant DNA_MODULUS = 10 ** DNA_DIGITS;
    uint32 internal constant COOLDOWN_TIME = 1 days;

    // --- Data structures -----------------------------------------------------

    struct Zombie {
        string name;         // dynamic string (pointer)
        uint256 dna;         // 16-digit DNA (stored in uint256)
        uint32 level;        // starting at 1
        uint32 readyTime;    // UNIX timestamp when the zombie is "ready"
        uint16 winCount;     // battles won
        uint16 lossCount;    // battles lost
    }

    // --- Storage -------------------------------------------------------------

    Zombie[] public zombies;

    /// @notice Returns the owner address for a given zombie ID
    mapping(uint256 => address) public zombieToOwner;

    /// @notice Number of zombies owned by an address
    mapping(address => uint256) public ownerZombieCount;

    // --- Internal mint -------------------------------------------------------

    /**
     * @notice Internal factory to create a zombie
     * @dev Sets owner, initializes cooldown, and emits {NewZombie}
     * @param _name Zombie name
     * @param _dna 16-digit DNA
     * @return id Newly created zombie ID
     */
    function _createZombie(string memory _name, uint256 _dna) internal returns (uint256 id) {
        uint32 ready = uint32(block.timestamp + COOLDOWN_TIME);
        zombies.push(Zombie({name: _name, dna: _dna, level: 1, readyTime: ready, winCount: 0, lossCount: 0}));
        id = zombies.length - 1;

        zombieToOwner[id] = msg.sender;
        unchecked {
            ownerZombieCount[msg.sender] += 1; // safe in 0.8; unchecked to save gas
        }

        emit NewZombie(id, msg.sender, _name, _dna);
    }

    // --- Pseudo-randomness ---------------------------------------------------

    /**
     * @notice Produces a pseudo-random DNA value from a string
     * @dev DO NOT use on mainnet; predictable/manipulable
     * @param _str Input string (typically the name)
     * @return dna 16-digit DNA
     */
    function _generateRandomDna(string memory _str) private view returns (uint256 dna) {
        uint256 rand = uint256(keccak256(abi.encodePacked(_str, msg.sender)));
        dna = rand % DNA_MODULUS;
    }

    // --- Public API ----------------------------------------------------------

    /**
     * @notice Creates the first zombie for the caller (max one per address)
     * @dev Rounds DNA down to the nearest hundred to make last two digits 00
     * @param _name Desired zombie name
     * @return zombieId Newly created zombie ID
     */
    function createRandomZombie(string memory _name) external returns (uint256 zombieId) {
        require(ownerZombieCount[msg.sender] == 0, "Already has a zombie");
        uint256 randDna = _generateRandomDna(_name);
        randDna = randDna - (randDna % 100);
        zombieId = _createZombie(_name, randDna);
    }
}
