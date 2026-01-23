# Zero Address / Zero Amount Reverts
## Summary

Some ERC-20 tokens revert when:
1. `transfer` / `transferFrom` is called:
- to `address(0)`
- from `address(0)`

2. `transfer(amount = 0)` is executed - even with valid addresses

This behavior is not forbidden by the ERC-20 standard.
It is an implementation choice, and many widely used tokens follow it.

## Why This Is an Edge Case

Many protocols contain logic where:
- `amount` may become `0` in boundary conditions
- recipient addresses may be:
  - uninitialized
  - dynamically computed
  - provided from external input
- `transfer` is part of a larger execution flow

If the protocol does not expect a revert, it may:
- break entirely
- become permanently blocked (DoS)
- end up in an inconsistent state

## Important Observation (OpenZeppelin)

Even OpenZeppelin’s ERC-20 implementation enforces:
```
require(from != address(0), "ERC20: transfer from the zero address");
require(to != address(0), "ERC20: transfer to the zero address");
```

This means:
- `transfer(from = address(0))` → revert
- `transfer(to = address(0))` → revert

➡️ This is de facto standard behavior, not an exotic edge case.

## Zero-Amount Transfers - A More Subtle Case

Some tokens:
- allow `transfer(0)`
- others revert on `transfer(0)`

This becomes dangerous when a protocol:
- does not guard against `amount == 0`
- performs transfers inside loops
- uses transfers as part of cleanup or settlement logic

## Impact
### 1. Denial of Service (DoS)

Example:
- user triggers a flow where `amount == 0`
- token reverts on `transfer(0)`
- the function becomes permanently unusable

Especially critical in:
- public functions
- batch operations
- rebalance / settle / harvest logic

### 2. Blocked Execution Paths

If `transfer` is used as:
- a “no-op”
- a conditional step
- part of a generic pipeline

A zero-amount revert may block the entire execution flow.

### 3. Broken Invariants

Protocols may implicitly assume:

> "`transfer(0)` is always safe."

This assumption is false for many ERC-20 implementations.

## Potential Attack Vectors
### 1. User-Triggered DoS
- call a function that results in `amount == 0`
- token reverts
- the function always fails

### 2. Governance / Configuration Griefing
- destination address is set to `address(0)` as a placeholder
- token reverts
- core functionality becomes blocked

## Where This Commonly Appears
- universal vaults
- batch payout logic
- fee distribution
- cleanup / sweep functions
- protocol adapters

## Audit Checklist
### What to Verify
- Can `amount == 0` occur?
- Is there an explicit `require(amount > 0)`?
- Can the recipient be `address(0)`?
- Are transfers executed inside loops?
- Is `address(0)` used as a sentinel value?

## 🚩 Red Flags

- `token.transfer(to, amount)` without checking:
  - `to != address(0)`
  - `amount > 0`

- generic pipelines for arbitrary tokens
- missing guards in batch functions

## Correct Defensive Approaches
### Option 1 - Arbitrary Tokens

✔️ Explicitly guard amount > 0
✔️ Never use address(0) as a recipient
✔️ Never assume transfer(0) is a no-op

### Option 2 - Whitelisted Tokens

✔️ Review each token implementation
✔️ Document assumptions explicitly

⚠️ Still account for:
- future upgrades
- governance changes

## A Common Mental Trap

You might think:

> "If I withdraw 0 and it reverts - that’s fine, I lost nothing."

In practice, protocols often look like this:
```
function withdraw() external {
    uint256 amount = calculateAmount(msg.sender); // may be 0
    token.transfer(msg.sender, amount);            // ❌ revert
    userBalance[msg.sender] = 0;
}
```

⚠️ Key detail:
- state update happens after transfer
- execution never reaches it
- the user is permanently blocked

### Real Issue #1 - Permanent Lock (DoS)

Scenario:
- `calculateAmount()` returns `0`
- token reverts on `transfer(0)`
- `withdraw()` always reverts
- the user can never complete withdrawal

Even if the “asset” is:
- a share
- a position
- a future withdrawal right

➡️ This is a hard lock, not “failed zero withdrawal”.

### Real Issue #2 - Zero Is Not User-Selected

Zero amounts often arise from:
- rounding
- division by shares
- fee-on-transfer behavior
- rebasing
- time-based rewards
- precision mismatches

The user did not choose `0`.

### Real Issue #3 - Invariant Breaks
```
function exit() external {
    withdraw();      // ❌ revert
    claimRewards();  // never executed
    closePosition(); // never executed
}
```

If `withdraw()` reverts on `transfer(0)`:
- position remains open
- rewards are never settled
- protocol enters a “zombie state”

### Real Issue #4 - Batch / Loop DoS
```
for (uint256 i = 0; i < users.length; i++) {
    token.transfer(users[i], rewards[i]);
}
```

If one user has `rewards[i] == 0`:
- entire loop reverts
- no one gets paid
- attacker can intentionally block payouts

## Why Auditors Treat This as a Vulnerability

Because:
- a single edge case
- breaks the entire execution path
- without fallback
- without recovery

This is classic Denial of Service via unexpected revert.

## Why "It’s Just Zero" Is Dangerous

In the EVM:
- `0` is a valid state
- not a no-op
- if execution reaches it, it must be handled

## Correct Vulnerability Framing

❌ Bad:
```
“transfer(0) fails”
```

✅ Correct:

```
"Unexpected revert on zero-amount transfers prevents users from completing withdrawal flows, leading to permanent denial-of-service for affected positions."
```

## Reporting Guidance

Example:

> The protocol performs token transfers without guarding against zero-address or zero-amount transfers. Some ERC-20 implementations (including OpenZeppelin’s) revert on such operations, which may lead to denial-of-service scenarios or blocked execution paths.

## Knowledge Base Takeaways
- zero address → commonly reverts
- zero amount → not guaranteed to be safe
- this is widespread behavior, not an edge implementation
- arbitrary tokens → must handle both cases
- frequent source of DoS vulnerabilities
