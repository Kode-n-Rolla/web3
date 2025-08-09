// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "./ZombieHelper.sol";

/**
 * @title ZombieAttack (CryptoZombies practice)
 * @author kode-n-rolla
 * @notice Simple battle mechanics between two zombies.
 * @dev Uses pseudo-randomness; NOT suitable for production (replace with VRF/commit-reveal for real apps).
 */
contract ZombieAttack is ZombieHelper {
    // -----------------------------------------------------------------------
    // Config
    // -----------------------------------------------------------------------

    /// @notice Chance to win in percent (0..100)
    uint8 public constant ATTACK_VICTORY_PROBABILITY = 70;

    // -----------------------------------------------------------------------
    // Events
    // -----------------------------------------------------------------------

    /// @notice Emitted after an attack is resolved
    event AttackResolved(
        uint256 indexed attackerId,
        uint256 indexed targetId,
        bool attackerWon,
        uint32 attackerLevel,
        uint16 attackerWins,
        uint16 attackerLosses,
        uint16 targetWins,
        uint16 targetLosses
    );

    // -----------------------------------------------------------------------
    // State (pseudo-randomness nonce)
    // -----------------------------------------------------------------------

    /// @dev Nonce to perturb keccak256; purely for demo randomness
    uint256 private randNonce;

    // -----------------------------------------------------------------------
    // Internal randomness (demo only)
    // -----------------------------------------------------------------------

    /**
     * @notice Returns a pseudo-random number in [0, _modulus)
     * @dev DO NOT use on mainnet. For real apps use Chainlink VRF or commit-reveal.
     */
    function randMod(uint256 _modulus) internal returns (uint256) {
        unchecked {
            randNonce += 1;
        }
        // Post-merge chains have block.prevrandao; still predictable/manipulable by validators.
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.prevrandao, block.timestamp, msg.sender, randNonce)
                )
            ) % _modulus;
    }

    // -----------------------------------------------------------------------
    // Battles
    // -----------------------------------------------------------------------

    /**
     * @notice Attack another zombie with your zombie
     * @dev Requires ownership of the attacker; attacker must be ready (no cooldown).
     *      On win: +1 win, +1 level, defender +1 loss, and spawn a new zombie via {feedAndMultiply}.
     *      On loss: +1 loss, defender +1 win, attacker enters cooldown.
     * @param _zombieId Attacker zombie id (must be owned by caller)
     * @param _targetId Defender zombie id
     */
    function attack(uint256 _zombieId, uint256 _targetId) external onlyOwnerOf(_zombieId) {
        require(_zombieId < zombies.length && _targetId < zombies.length, "Invalid zombie id");
        require(_zombieId != _targetId, "Self-attack not allowed");

        Zombie storage attacker = zombies[_zombieId];
        Zombie storage defender = zombies[_targetId];

        // Ensure attacker is ready (feedAndMultiply also checks, but we fail fast here)
        require(_isReady(attacker), "Attacker on cooldown");

        uint256 roll = randMod(100);
        bool attackerWon = roll < ATTACK_VICTORY_PROBABILITY;

        if (attackerWon) {
            unchecked {
                attacker.winCount += 1;
                attacker.level += 1;
                defender.lossCount += 1;
            }
            // Will also trigger cooldown for the attacker via feedAndMultiply()
            feedAndMultiply(_zombieId, defender.dna, "zombie");
        } else {
            unchecked {
                attacker.lossCount += 1;
                defender.winCount += 1;
            }
            _triggerCooldown(attacker);
        }

        emit AttackResolved(
            _zombieId,
            _targetId,
            attackerWon,
            attacker.level,
            attacker.winCount,
            attacker.lossCount,
            defender.winCount,
            defender.lossCount
        );
    }
}
