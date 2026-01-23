# Fee-on-Transfer & Rebasing Tokens
## Summary

Some ERC-20 tokens modify balances during or immediately after a transfer.
This behavior deviates from the common ERC-20 assumption that the transferred `amount` equals the amount actually received.

This category includes:
- Fee-on-transfer tokens - a percentage is deducted during transfer
- Rebasing tokens - balances may change dynamically due to supply rebases

Many protocols fail to account for this behavior, leading to broken accounting and economic exploits.

## Token Behaviors
### Fee-on-Transfer Tokens

A fee is deducted during `transfer` / `transferFrom`.

Example:
- Sent: `100`
- Fee: `6`
- Received: `94`

### Rebasing Tokens

Balances may change:
- during the transfer
- immediately after the transfer
- without an explicit `transfer` call

As a result:
- the receiver may get more or less than expected
- balances may change asynchronously

## Core Issue

Protocols often assume that the `amount` passed to `transferFrom` equals the number of tokens actually received.

This assumption is incorrect.

## Typical Vulnerable Pattern
❌ Incorrect Accounting
```
token.transferFrom(msg.sender, address(this), amount);
// Assumes exactly `amount` tokens were received
accounting += amount;
```
### Why This Is Dangerous
- Fee-on-transfer → fewer tokens are received
- Rebasing tokens → received amount is unpredictable

## Correct Accounting Pattern

Protocols must never assume how many tokens were received.
They must measure the actual balance delta.

✅ Correct Pattern
```
uint256 balanceBefore = token.balanceOf(address(this));

token.transferFrom(msg.sender, address(this), amount);

uint256 balanceAfter = token.balanceOf(address(this));
uint256 received = balanceAfter - balanceBefore;

// Use `received`, not `amount`
accounting += received;
```

This is the only correct way to safely support:
- fee-on-transfer tokens
- rebasing tokens
- any non-standard ERC-20 implementation

## Impact

Using `amount` instead of the actual received balance can lead to:

### 🔴 Accounting Failures
- inflated deposits
- incorrect share calculations

### 💸 Economic Exploits
- deposit `100`
- receive credit for `100`
- actually transfer `94`

### 🧨 Broken Protocol Logic
- reward distribution
- withdrawal limits
- vault invariants

### ⚠️ Silent Bugs
- no revert
- failures only visible in accounting discrepancies

## Potential Attack Vectors
1. Share Inflation
  - attacker deposits a fee-on-transfer token
  - protocol mints shares based on `amount`
  - attacker withdraws more than contributed

2. Accounting / Oracle Desynchronization
- internal accounting diverges from real balances
- downstream logic operates on incorrect data

3. Rebase Abuse
- rebase occurs during or after transfer
- attacker benefits from protocol assumptions

## High-Risk Protocol Types
Especially dangerous in:
- vaults
- lending / borrowing protocols
- staking systems
- AMM wrappers
- bridges
- protocol adapters

## Audit Checklist
### Questions to Ask
- Is amount used directly after transferFrom?
- Is balanceBefore / balanceAfter measured?
- Does the protocol accept arbitrary ERC-20 tokens?
- Is fee-on-transfer behavior explicitly unsupported?

### 🚩 Red Flags
- `accounting += amount`
- `shares = amount`
- `require(amount > 0)` without validating received balance

## Key Mental Model
Always answer one question first:

- Does the protocol accept arbitrary ERC-20 tokens or a strictly limited set?

This single decision determines the entire audit strategy.

### Scenario 1 - Arbitrary ERC-20 Tokens Accepted
🔴 Most Dangerous Case

If:
- users can supply arbitrary tokens
- accounting relies on `amount`

→ this is always a red flag, no exceptions.

Risk Statement Example:
> The protocol assumes that the input `amount` equals the actual received token balance while accepting arbitrary ERC-20 tokens, which breaks accounting for fee-on-transfer and rebasing tokens.

UI restrictions or current usage assumptions are not valid mitigations.

### Scenario 2 - Whitelisted Tokens
Question 1: Is the Whitelist Mutable?
Check whether:
- governance can add tokens
- proxies can upgrade logic
- adapters introduce new tokens
A mutable whitelist is effectively arbitrary.

Question 2: Is Each Token Safe?
Each token must be evaluated individually:
- fee-on-transfer?
- burn-on-transfer?
- rebasing?
- reflection?
- callbacks?

## Practical Audit Methodology
### 1. Review Token Code (if available)
Look for:
- overridden `_transfer`
- transfer fees
- supply rebasing logic
- hooks or callbacks
A single fee-on-transfer token requires full protocol support.

### 2. Verify Accounting Logic

❌ Unsafe:
```
deposits[token] += amount;
```

✅ Safe:
```
uint256 received = balanceAfter - balanceBefore;
deposits[token] += received;
```
### 3. Check Consistency Across Tokens
Common bug:
- safe path for USDC
- unsafe path for exotic tokens

Often caused by:
- different adapters
- legacy branches
- inconsistent handling

### Scenario 3 - Fixed, Immutable Tokens (USDC, DAI, WETH)

Still verify:
- wrappers
- future upgrades
- governance hooks

If tokens are immutable and known to be non-fee-on-transfer, using `amount` may be acceptable - but this should be explicitly documented.

## Common Protocol Mistake

> "We only accept token X, so this is safe."

But later:
- governance adds token Y
- proxy upgrades logic
- adapters accept token Z

This creates latent risk that surfaces later.

Reporting Guidance

Do not blame the token - document the assumption.

Example:

> Although the protocol currently supports a limited set of tokens, accounting relies on the input amount rather than the actual received balance. If a fee-on-transfer or rebasing token is added in the future (via governance or upgrades), core invariants would break.

Mental Checklist
| Question                   | If Yes                |
| -------------------------- | --------------------- |
| Arbitrary tokens accepted? | `amount` ❌            |
| Whitelist mutable?         | effectively arbitrary |
| Accounting uses `amount`?  | red flag              |
| Token behavior changeable? | latent risk           |
| Balance delta measured?    | ✅                     |
