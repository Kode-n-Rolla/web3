# Revert on Large Approvals or Transfers (Caps / `uint96`)
## Summary

Some ERC-20 tokens impose upper bounds on `approve` or `transfer` amounts.

Common examples:
- using `uint96` instead of `uint256` for allowances or balances
- explicit caps enforced in token logic

As a result:
- `approve(type(uint256).max)` → **revert**
- `transfer(very_large_amount)` → **revert**

Even when:
- the balance is sufficient
- the operation is logically valid

## Why This Exists

Typical reasons include:
- storage optimization
- legacy design decisions
- gas efficiency
- historical implementations (e.g. Compound / UNI-style tokens)

📌 This is **legal ERC-20 behavior**, but non-standard.

## Where Protocols Break

A very common pattern in protocols:
```
token.approve(spender, type(uint256).max);
```

If the token:
- stores allowance as `uint96`
- or enforces an internal cap

➡️ `approve` reverts
➡️ the entire function fails
➡️ DoS

## Why This Can Be Critical
### 🔴 Consequences
- deposits, swaps, or adapter logic break
- "infinite approval" strategy fails
- migration or upgrade flows are blocked
- users cannot interact with the protocol

### Severity
- usually *Medium*
- can be High if `approve` is in a critical execution path

## Audit Checklist

Ask:
- Is `type(uint256).max` used anywhere?
- Does the protocol assume "infinite approval"?
- Is there a fallback such as:
  - `forceApprove`
  - bounded approvals

- Are tokens with capped allowances explicitly considered?

## Mitigation Strategies

Realistic options include:
- using `forceApprove`
- using bounded allowances
- avoiding reliance on infinite approvals
- documenting assumptions explicitly

## Short Conclusion
- not all tokens accept "infinite" approvals
- large approvals can revert
- infinite approval is not a universal pattern
- arbitrary ERC-20 → potential DoS
