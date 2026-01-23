# Non-Zero Approvals (USDT-Style)
## Summary

Some ERC-20 tokens (most notably USDT) **disallow changing an allowance directly from a non-zero value to another non-zero value**.

Forbidden:
```
allowance = 5;
approve(spender, 10); // ❌ revert
```

Allowed:
```
approve(spender, 0);
approve(spender, 10); // ✅
```

This is an intentional design choice, not a token bug.

## Why This Exists (Important Context)

This behavior protects users from the classic approve front-running attack:

**Attack flow**
1. Alice grants Bob `allowance = 5`
2. Alice submits `approve(10)` to increase allowance
3. Bob front-runs and spends `5`
4. Alice’s tx mines → allowance becomes `10`
5. Bob spends another `10`

➡️ Bob spends `15` total, while Alice intended `10`.

## How USDT Protects Against This

USDT enforces:

> "If allowance ≠ 0, you must reset it to 0 first."

This forces the user to:
- notice allowance usage
- reconsider the second approval
- avoid blind overwrites

📌 This is user protection, not a vulnerability in the token.

## Where Protocols Break

Problems arise when protocols don’t account for this behavior.

### Vulnerable Pattern
```
token.approve(spender, amount);
```

If:
- current allowance ≠ 0
- token follows USDT-style rules

➡️ `approve` reverts
➡️ protocol function fails
➡️ potential DoS

## Why This Becomes a Protocol Vulnerability

`approve` is often used in critical paths, including:
- deposits
- rebalancing
- swaps
- adapter logic
- migrations / upgrades

If `approve` reverts:
- the operation cannot complete
- users may be blocked
- systems can get stuck

## Why This Is NOT “User Error”

Key points:
- users don’t control how tokens implement approve
- users don’t control how protocols call approve
- protocols advertise support for these tokens

➡️ The protocol must adapt, not the user.

## Where This Commonly Breaks Systems
### 🔴 High-Risk Scenarios
1. Adapters / routers
2. Upgrade or migration logic
3. Multi-step swaps
4. Cross-protocol interactions
5. Automated strategies

Especially dangerous when:
- approve is called automatically
- current allowance is not checked

## Audit Checklist
### What to Verify

- Is `approve()` used directly?
- Is there:
  - `approve(0)` before `approve(amount)`?
  - `forceApprove` (OpenZeppelin)?

- Does the protocol support USDT / USDC-style tokens?
- Can approve be called multiple times within one flow?

## Correct Patterns (Mitigation)
### ✅ Best Practice - `SafeERC20.forceApprove`
```
token.forceApprove(spender, amount);
```

Behavior:
- tries `approve(amount)`
- if it reverts → `approve(0)` → `approve(amount)`

## ⚠️ Manual Alternative
```
token.approve(spender, 0);
token.approve(spender, amount);
```

Downsides:
- riskier with reentrancy
- worse composability
- more error-prone

## Prefer Relative Updates When Possible

If the goal is to adjust, not overwrite:
- `safeIncreaseAllowance(spender, delta)`
- `safeDecreaseAllowance(spender, delta)`

These reduce front-running risk.
However, **USDT-style** restrictions may still require `forceApprove`.

## Practical Audit Rule

If you see:
- support for USDT-style tokens
- logic that "sets allowance to N"
- repeated `approve()` calls

👉 Look for `forceApprove()` (or zero-reset), not plain `approve()` or `safeApprove()`.

## Why This Is a Real Edge Case (Not a Minor Detail)

Because:
- token behavior is legitimate
- revert is expected
- protocol is unprepared
- result is DoS

## Knowledge Base Takeaways
- non-zero → non-zero `approve` may revert
- this protects users from `approve` front-running
- but becomes a DoS vector for protocols
- always account for USDT-style approvals
- use `forceApprove` or zero-reset patterns
