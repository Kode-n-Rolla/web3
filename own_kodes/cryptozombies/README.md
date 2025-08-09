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

# 📌 TODO / Roadmap

## Must‑have (next PR)
- ERC-721 actions in UI: transferFrom, approve, ownerOf, balanceOf (buttons + inputs).

- Admin mini-panel: kittyContract (view) + setKittyContractAddress, levelUpFee (view) + setLevelUpFee, withdraw (only available to owner).

- Feed / Level Up per zombie: “Feed on Kitty” button (enter Kitty ID), Level Up button (uses levelUpFee() from contract).

- Activity feed (real-time): subscribe to NewZombie and AttackResolved + show last 5–10 events.

- Front-end caching: in-memory Map<id, zombie>; on refresh fetch only new/changed zombies.

- Transaction UX: disable buttons while pending, show status + link to block explorer.

- Network check: warn user if chainId ≠ target network (e.g., Sepolia).

## Nice-to-have (later)
- Permalink pages: /zombie/:id (zombie details) and /user/:address (user’s army; “Attack this zombie” button).

- Attack UI: modal to pick your zombie (grey out if in cooldown), input “Attack by ID”, and “Attack random” button.

- Welcome flow: if no zombies, show banner “Create your first zombie”.

- More events in UI: display LevelUpFeeUpdated, NameChanged, DnaChanged, Withdrawn.

- Randomness upgrade: future branch for VRF/commit-reveal randomness.

- Owner index: store tokenIds per owner to avoid O(n) lookups.

- Full ERC-721 compliance: migrate to OZ ERC721 (safeTransferFrom, operator approvals, receiver check).
