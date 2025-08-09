# CryptoZombies — Modernized Course Implementation

This repository contains my **updated and refactored** implementation of the [CryptoZombies](https://cryptozombies.io/) Solidity course.  
The original course was written for Solidity 0.5.x — I’ve upgraded all contracts to **Solidity ^0.8.24**, added NatSpec documentation, events, safer patterns, and a basic front-end for interaction.

---

## 📂 Structure
cryptozombies/
<br>├── contracts/
<br>│ ├── ZombieFactory.sol
<br>│ ├── ZombieFeeding.sol
<br>│ ├── ZombieHelper.sol
<br>│ ├── ZombieAttack.sol
<br>│ ├── ZombieOwnership.sol
<br>│ ├── ERC721.sol (Minimal interface)
<br>│ └── Ownable.sol (Minimal Ownable)
<br>├── frontend/ # Simple HTML/JS front-end
<br>│ ├── index.html
<br>│ ├── cryptozombies_abi.js
<br>│ └── web3.min.js (v1.10.4)

---

## 🛠 Features

- **Solidity ^0.8.24** — no SafeMath needed, built-in overflow checks
- **NatSpec documentation** for all contracts and public/external functions
- **Events** for major actions: zombie creation, attacks, leveling, name/DNA changes, withdrawals
- **Better patterns**:
  - `call` for withdrawals
  - Access checks & zero address guards
  - Approval clearing on transfer
  - Constants for config values
- **Frontend**: minimal UI with wallet connect, create zombie, feed, level up, display list

---

## 🚀 Getting Started

### Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation) for compiling and testing
- [MetaMask](https://metamask.io/) for frontend interaction
- Node.js (optional, for local static server)

### Compile & Test
```bash
forge build
forge test
```
### Deploy (example with Foundry)
```bash
forge create src/ZombieOwnership.sol:ZombieOwnership \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

## 🌐 Frontend
The <code>frontend</code> folder contains a simple index.html using web3.js and cryptozombies_abi.js.
To run it locally:
```bash
# In the frontend directory
python3 -m http.server 1337
# Or use any local web server
```
Then open: http://localhost:1337

Update index.html → contract address input with your deployed contract address.

## 📌 TODO / Roadmap
- Randomness: replace pseudo-randomness with Chainlink VRF or commit-reveal

- ERC-721 compliance: migrate to OpenZeppelin ERC721 (safe transfers, operator approvals)

- Add pending tx status & links to explorer

- Render live events feed (AttackResolved, NewZombie)

- Network guard (Sepolia/Goerli check)

- Gas optimizations: per-owner token indexing to avoid O(n) scans

- Security: Anti-grief rules for repeated attacks


