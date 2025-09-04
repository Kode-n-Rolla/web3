# Section 4 – Cyfrin Smart Contracts Security Course

### NFT challenge solution via reentrancy (predictable RNG).

This repo contains my solution to the Section 4 “Puppy Raffle Audit / S4” NFT challenge from the Cyfrin <a href='https://updraft.cyfrin.io/courses/security'>Smart Contracts Security course</a>.
The exploit uses a controlled reentrancy into solveChallenge and a predictable RNG computed within the same transaction.

Target challenge contract (S4) 👉 <a href='https://sepolia.etherscan.io/address/0xf988ebf9d801f4d3595592490d7ff029e438deca#code'>here</a>

### What’s inside

- `src/SolveContract.sol` – attacker contract (owner check spoofing, reentrancy entrypoint, ERC-721 receiver, sweep).
- `test/S4_Solve.t.sol` – unit + e2e tests (mock registry + test ERC-721).
- `src/dev/TestNFT.sol`, `src/dev/OzRegistry.sol` – local/dev helpers.
- `script/LocalAnvil.s.sol` – local integration script (Anvil).

### Why the bug exists (short)

1. <b>Owner check that trusts the caller:</b>
`S4::solveChallenge` does `staticcall` to `msg.sender.owner()` and then requires `ownerAddress == msg.sender`.
My attacker’s `owner()` simply returns `address(this)`, so the check passes.

2. <b>Two-phase flow with an external call:</b>
First call sets `myVal = 1` and then performs `call(msg.sender).go()`. Inside `go()` I re-enter `solveChallenge(...)`.

3. <b>Predictable randomness within the same tx:</b>
In the second call (where `myVal == 1`) S4 computes:
```solidity
rng = uint256(keccak256(abi.encodePacked(msg.sender, block.prevrandao, block.timestamp))) % 1_000_000;
```

Because both calls occur <b>in the same transaction</b>, `block.timestamp` and `block.prevrandao` are unchanged.
My `go()` computes the exact same `rng` with `address(this)` and passes it as `guess`.

4. <b>NFT is minted to msg.sender:</b>
`Challenge::_updateAndRewardSolver` mints the NFT to `msg.sender`, which is my attacker contract on the second call.
I implement `onERC721Received` so `safeMint` succeeds, then I `sweep721` the token to my EOA.

<b>Root causes:</b> external call between state transitions; predictable RNG; trusting caller-supplied `owner()`.

### Attack flow (one transaction)

1. EOA → `SolveContract::solvingChallenge()`
2. Attacker → `S4::solveChallenge(0, ...)`
3. S4 → `SolveContract::owner()` (staticcall, returns `address(this)`) ✅
4. S4 → `SolveContract::go()`
5. `go()` computes `guess = f(address(this), prevrandao, timestamp)` and re-enters
→ `S4::solveChallenge(guess, ...)`
6. S4 (second entry) validates guess → registry mints NFT to attacker → `onERC721Received` fires ✅
7. After tx: call `sweep721(nft, tokenId)` → NFT → EOA.

## Localy testing (Foundry)

```bash
forge build
forge test -vvv
```

What the tests cover:
- Happy path (two entries + mint + sweep).
- Guards: `go()` callable only by S4; `solvingChallenge()` only by owner.
- Optional debug events (`DebugGuess`, `NftReceived`, `NftSwept`) for traceability.

## Local integration (Anvil)


In one terminal:
```bash
anvil
```
Save any private key to `.env` with `PRIVATE_KEY` and RPC url (`http://127.0.0.1:8545`) with `RPC_URL`
Then update env
```bash
source .env
```

In another
```bash
forge script script/LocalAnvil.s.sol \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast -vvvv
```
Expected logs:
```
Owner after mint : <SolveContract address>
Owner after sweep: <your EOA>
```

## Sepolia reproduction

Save your next env variables to `.env`:
- SEPOLIA URL like `SEPOLIA_RPC="https://sepolia.infura.io/v3/<KEY>`
- Your private key like `PRIVATE_KEY=[YOUR_PRIVATE_KEY]`
- Target contract address like `S4=0xf988Ebf9D801F4D3595592490D7fF029E438deCa`

Update enviroment
  ```bash
  source .env
  ```

1. Deploy solver contract:
  ```bash
  forge create src/SolveContract.sol:SolveContract \
    --rpc-url $SEPOLIA_RPC --private-key $PRIVATE_KEY \
    --constructor-args $S4
  ```
Save output "Deployed to: ..." as ATTACKER to `.env` like `ATTACKER=0x<deployed_attacker>`

2. Trigger the exploit (both entries happen inside this `tx`)
```bash
cast send $ATTACKER "solvingChallenge()" \
  --rpc-url $SEPOLIA_RPC --private-key $PRIVATE_KEY
```

3. From the tx receipt, find NFT + tokenId (ERC-721 Transfer topic)
```bash
cast receipt 0x<tx_hash> --rpc-url $SEPOLIA_RPC
```

4. Sweep NFT to your EOA
Save from logs `NFT address` and `tokenId` or just copy and paste.
```bash
cast send $ATTACKER "sweep721(address,uint256)" $NFT $ID \
  --rpc-url $SEPOLIA_RPC --private-key $PRIVATE_KEY
```

5. Verify ownership
```bash
cast call $NFT "ownerOf(uint256)(address)" $ID --rpc-url $SEPOLIA_RPC
# => your EOA
```

## Mitigations (what to fix)

- Avoid external calls between state updates and validation (or use a reentrancy guard).
- Use <a href='https://docs.chain.link/vrf'>ChainlinkVRF</a> for random numbers; don’t rely on timestamp/prevrandao for critical decisions.
- Don’t trust msg.sender.owner(): the callee controls its code. If identity matters, redesign the trust boundary.

## Repo structure
I didn`t copy target contracts. This repo contains only my own files. You should copy target contracts by yourself.
```
├── script
│   └── LocalAnvil.s.sol
├── src
│   ├── dev
│   │   ├── OzRegistry.sol
│   │   └── TestNFT.sol
│   └── SolveContract.sol
├── test
|   └── S4_Solve.t.sol
└── .env

```

## Requirements
- Foundry (forge/cast)
- Node RPC (Anvil for local, Infura/Alchemy for Sepolia)
- OpenZeppelin Contracts (installed via `forge install`)

