# 🧠 Lesson Nine NFT Challenge – Foundry PoC

This repository contains the full solution to the NFT Challenge ([Lesson Nine](https://sepolia.etherscan.io/address/0x33e1fD270599188BB1489a169dF1f0be08b83509#code)) from Cyfrin Course using [Foundry](https://book.getfoundry.sh/). The exploit is executed via a forked Sepolia network and demonstrates how to craft calldata to pass internal contract checks.

## 🧰 Project Structure

```
nft_challange/
├── src/
│   └── ILessonNine.sol       # Interface of the challenge contract
├── test/
│   └── HackSolve.t.sol       # Forge test with PoC exploit
├── .env                      # Contains RPC + target data
├── foundry.toml              # Foundry config
└── README.md                 # This file
```

---

## ⚙️ Setup

### 1. Init project

```bash
forge init nft_challeange
cd nft_challeange
```

### 2. Create `.env` file

```env
SEPOLIA_RPC=https://sepolia.infura.io/v3/YOUR_KEY
TARGET=0x33e1fD270599188BB1489a169dF1f0be08b83509
FORK_BLOCK=8997426
```

Then:
```bash
source .env
```

### 3. Get latest block

```bash
cast block-number --rpc-url $SEPOLIA_RPC
# => 8997426
```

### 4. Get block data

```bash
cast block $FORK_BLOCK --rpc-url $SEPOLIA_RPC
```

Take:
- `timestamp`
- `mixHash` (also known as `prevrandao`)

---

## 🔓 Exploit Logic

### 5. Reverse engineering `keccak256(abi.encodePacked(...))`

Check what input gives hash ending in specific digits (`% 100000 == 90451`)

```bash
cast keccak "attacker"
# => take last 40 hex chars → this is attackerEOA
```

In our case:
```solidity
address attackerEOA = 0x97154a62Cd5641a577e092d2Eee7e39Fcb3333Dc;
```

### 6. Encode calldata

```bash
cast abi-encode "f(address,uint256,uint256)" \
  0x97154a62cd5641a577e092d2eee7e39fcb3333dc \
  0x3a70aa522079213bdc793c26a907be816c6a3c7421eb2c566f80992c4bb6eaaa \
  1755355572
```

Then hash the result:
```bash
cast keccak 0x<output>
```

Check if `% 100000 == 90451`.

---

## 🧪 Write the test

Create `test/HackSolve.t.sol`:

```solidity
function test_ExploitWithInternalCall() public {
    vm.createSelectFork(vm.envString("SEPOLIA_RPC"), vm.envUint("FORK_BLOCK"));
    vm.prank(attackerEOA);
    ILessonNine(TARGET).solveChallenge(prevrandao, timestamp);
}
```

> Make sure `ILessonNine.sol` contains the `solveChallenge(...)` definition.

---

## 🚀 Run

```bash
forge test --mc HackSolve -vvv
```

Expected output:

```
Ran 1 test for test/HackSolve.t.sol:HackSolve
[PASS] test_ExploitWithInternalCall() (gas: 621045)
Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 399.25ms (1.14ms CPU time)

Ran 1 test suite in 401.88ms (399.25ms CPU time): 1 tests passed, 0 failed, 0 skipped (1 total tests)
```

---

## 🧠 Notes

- We don't deploy any contract – we call existing deployed contract using interface.
- `makeAddr("attacker")` won't work because address must satisfy a specific hash.
- `prevrandao` is modern alias for `mixHash`.
- This method isolates and reproduces on-chain challenge reliably with Foundry.
