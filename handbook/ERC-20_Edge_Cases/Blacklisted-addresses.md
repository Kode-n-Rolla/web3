# Blacklisted Tokens / Blacklisted Addresses
## Summary

Some ERC-20 tokens implement blacklist / blocklist / freeze mechanisms.
When an address is blacklisted, token operations involving it revert.

Depending on the implementation, checks may apply to:
- `transfer` → `msg.sender`, sometimes `to`
- `transferFrom` → `msg.sender`, `from`, `to`
- `approve` → sometimes restricted as well

Well-known examples include USDT and USDC, which use modifiers such as `notBlacklisted` and revert if `blacklisted[address] == true`.

### Key idea:
A protocol may rely on certain transfers must succeed, but blacklisting turns them into operations that can revert at any time due to external factors.

## Why This Is Dangerous (Impact)
### 🔴 Primary Risk: Denial of Service of Critical Flows

A blacklist acts as an external switch that can block protocol actions that are considered mandatory, such as:
- liquidations
- debt repayment / position closure
- collateral withdrawal or return
- reward or fee distribution
- batch operations (one address breaks the entire batch)

If a required step cannot complete, the protocol may:
- accumulate bad debt
- lose collateralization
- leave positions stuck
- break core invariants

## Where the Vulnerability Actually Appears

The issue is not that a user cannot transfer tokens.
The issue is that the protocol cannot complete an обязательный (mandatory) flow.

### Typical Example - Liquidation

A liquidation flow often includes:
1. selling part of the collateral
2. repaying the debt
3. returning the remaining collateral to a receiver

If the `receiver` (or any address involved in the transfer) is blacklisted for the collateral token:
- step (3) reverts
- the entire liquidation reverts

Result:
- the position remains open
- bad debt grows
- the protocol takes losses

## Potential Attack Vectors
### 1. Liquidation Griefing / DoS

An attacker engineers a situation where liquidation must return collateral to an address that:
- is already blacklisted, or
- may be blacklisted by an external party (issuer / token admin)

Depending on protocol design, the attacker may:
- choose the receiver address
- bind the position to a risky address
- force transfers to a fixed address (e.g., treasury) that later becomes blacklisted

### 2. Global DoS via Batch Operations
```
for (uint256 i = 0; i < users.length; i++) {
    token.transfer(users[i], amount);
}
```

If one user is blacklisted:
- the transfer reverts
- the entire batch fails
- no one receives funds

### 3. "Frozen Funds" as a Systemic Risk

If a protocol holds assets on an address or contract that becomes blacklisted:
- the protocol may become effectively insolvent for that asset
- withdrawals and repayments become impossible

This is especially critical for centralized stablecoins.

## Audit Checklist
### 1. Identify Tokens with Blacklist Mechanics

Common categories:
- centralized stablecoins
- compliance / sanction-aware tokens
- tokens with `freeze`, `blocklist`, or `blacklist` logic

### 2. Identify Mandatory Transfer Points

Pay special attention to flows such as:
- `liquidate()`
- `repayAndClose()`
- `withdraw()`
- `seize()`
- `claim()` / `distribute()`
- `sweep()` / `recover()`

Ask: Can the protocol continue if this transfer reverts?

### 3. Who Controls the Destination Address?
- user-controlled?
- protocol-controlled?
- fixed treasury?
- configurable address?

The less control the protocol has, the higher the DoS risk.

## Mitigation Strategies (Design-Dependent)

Common directions include:
- Pull over push - do not automatically send residual funds; let users claim them
- Escrow - keep leftovers inside the protocol until a successful withdrawal
- Fallback receivers - redirect on failure (dangerous, changes expectations)
- Asset whitelisting + explicit documentation (if blacklistable tokens are accepted intentionally)
- `try/catch` + accounting safety (only if partial execution is acceptable - often it is not)

📌 Important:
"Just catch the revert and continue" is often not possible, because the transfer may be part of a critical invariant.

## The Key Auditor Question

Blacklist is not an attack vector - it is an external failure source.

The real question is not:

> "Can an attacker add an address to the blacklist?"

But:

> "What happens to the protocol if a required address becomes blacklisted?"

## Why This Is Still a Vulnerability Without Attacker Control
### 1. Blacklist Control Is External but Realistic

Blacklist authority may belong to:
- token issuer (centralized)
- token governance / admin
- regulators / compliance processes
- sanctions enforcement

These are realistic external events, not hypothetical ones.

### 2. Attacker Can Design Blacklist-Sensitive Positions

The attacker does not need to control the blacklist.
They only need to create a position that cannot be resolved once blacklisting occurs.

Example:
- liquidation must return residual collateral
- receiver is an address likely to be blacklisted
- without that step, liquidation cannot complete

➡️ This is griefing / DoS, not “third-party fault”.

## The Most Important Criterion: Mandatory vs Optional
- If the protocol can skip the step → not a vulnerability
- If the protocol cannot progress without it → vulnerability

## Concrete Example - Lending Liquidation
1. position becomes undercollateralized

2. liquidation must:
  - repay debt
  - seize collateral
  - return remainder

If the final transfer reverts:
- liquidation fully reverts
- position stays open
- debt increases
- protocol accumulates bad debt

📌 The attacker only needs to create such a position.

## Why This Is Not a “Theoretical Edge Case”

Because:
- USDT / USDC actively use blacklists
- contracts are actually blacklisted in practice
- frozen funds incidents have happened
- lending, bridges, and vaults break on this behavior

This is systemic risk, not a profit-seeking exploit.

## How Auditors Classify This

Typically categorized as:
- Denial of Service
- Liquidation failure
- Protocol insolvency risk
- External dependency risk

Severity is often:
- **Medium** - if mitigations exist
- **High** - if it leads to bad debt or locked funds

## Why This Matters Without Direct Profit

Because:
- bug bounties ≠ only theft
- protocols fail when they cannot act
- bad debt is a real economic loss

## Knowledge Base Takeaways
- blacklist = external source of revert
- can DoS mandatory protocol flows
- especially dangerous in liquidations → bad debt
- always audit where transfers must succeed and to whom
