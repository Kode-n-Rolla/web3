# Transfer Less Than `amount`
## Summary

Some ERC-20 tokens may accept an `amount` parameter but **transfer fewer tokens than requested**, even when the behavior is **not** caused by:
- fee-on-transfer
- rebasing
- explicit transfer fees

Example behavior:
- `transfer(amount)` is called
- `amount = type(uint256).max`
- the token does not revert
- instead, it interprets this as:

> transfer the sender’s entire balance"

- and transfers `balanceOf(sender)`

📌 Result:
`amount ≠ actual transferred amount`

## Why This Is Allowed

The ERC-20 standard does not forbid this behavior.

A token implementation may legally:
- normalize the `amount`
- clamp it
- interpret it as a sentinel value
- treat `MAX_UINT` as "transfer all"

This behavior is unexpected, but fully valid under ERC-20.

## How This Differs from Fee-on-Transfer

It is important to distinguish the two:

### Fee-on-Transfer
- user sends `100`
- protocol receives `94`
- difference is explained by a fee

### Transfer-Less-Than-Amount
- user sends `MAX_UINT`
- protocol receives `balanceOf(sender)`
- no fee
- just a different interpretation of `amount`

➡️ The consequence is the same:
**the protocol must not trust `amount`**.

## Where the Vulnerability Appears

A protocol becomes vulnerable when it:
- uses `amount` for:
  - accounting
  - minting shares
  - enforcing limits

- does not verify the actual balance change

### Typical Unsafe Pattern
```
token.transferFrom(user, address(this), amount);
shares += amount; // ❌
```

If fewer tokens were actually received:
- shares are inflated
- invariants break
- value can be drained

## Why This Is Critical
### 🔴 Classes of Issues
- silent accounting corruption
- share inflation
- deposit cap bypass
- incorrect collateralization

All of this happens:
- without revert
- without errors
- without external signals

➡️ This makes the bug **extremely hard to detect**.

## Why This Matters for Arbitrary Tokens

If a protocol:
- accepts arbitrary ERC-20 tokens
- or has a mutable whitelist

➡️ it cannot assume that tokens:
- interpret `amount` literally
- do not normalize values
- do not treat `MAX_UINT` specially

Any token may:
- implement "MAX = transfer all"
- use `min(amount, balance)`
- apply other normalization logic

## Audit Checklist

Ask:
- Is `amount` used directly after `transfer` / `transferFrom`?
- Is `balanceBefore / balanceAfter` measured?
- Are there assumptions like:

> "`transfer(amount)` ⇒ `received == amount`"?

- Is `type(uint256).max` used anywhere?

## Universal Mitigation
### ✅ The Only Correct Approach
```
uint256 before = token.balanceOf(address(this));
token.transferFrom(user, address(this), amount);
uint256 received = token.balanceOf(address(this)) - before;
```

Then:
- always use `received`
- never trust `amount`

This protects against:
- fee-on-transfer tokens
- rebasing tokens
- transfer-less-than-amount behavior
- future token upgrades

## Knowledge Base Takeaways
- `amount` is a request, not a guarantee
- some tokens normalize `amount`
- actual transfers may be smaller
- balance delta is the only source of truth

## Short Conclusion
- this is not exotic behavior
- it is ERC-20-compliant
- it breaks naive accounting
- especially dangerous for arbitrary tokens
- mitigation is the same as fee-on-transfer
