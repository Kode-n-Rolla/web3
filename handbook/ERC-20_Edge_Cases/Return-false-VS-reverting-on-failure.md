# Return `false` vs Revert
## Summary

ERC-20 tokens may signal failure in two fundamentally different ways when an operation cannot be executed (`transfer`, `transferFrom`, `approve`):

1. Revert
- The transaction is reverted
- Execution stops
- State changes are rolled back

2. Return `false`
- The EVM call itself succeeds
- The token operation fails silently
- Execution continues unless the return value is explicitly checked

These represent two different expectation models for integrators.

## Why This Is Dangerous

If a protocol performs a token operation like this:
```
token.transfer(to, amount);
// assumes transfer succeeded
accounting += amount;
```

And the token returns `false` instead of reverting, the result is:
- no tokens were transferred
- the transaction continues
- internal accounting is updated
- protocol state becomes inconsistent

This often leads to:
- free minting
- free credit / collateral bypass
- share inflation
- broken accounting invariants

## Why `SafeTransfer` / `SafeERC20` Exists

The purpose of `SafeERC20` is to normalize token behavior.

OpenZeppelin’s `SafeERC20` wrappers:
- revert if the token returns `false`
- bubble up reverts from the token
 - safely handle tokens that return no data at all (another common non-standard case)

This gives integrators a single invariant:

> If `safeTransfer` succeeds, the transfer is guaranteed to have succeeded. Otherwise, the transaction reverts.

## Correct Integration Pattern
✅ Best Practice

Always use OpenZeppelin SafeERC20:
- `SafeERC20.safeTransfer`
- `SafeERC20.safeTransferFrom`
- `SafeERC20.forceApprove` (or carefully handle `approve`)

## ⚠️ If SafeERC20 Is Not Used

At minimum, the return value must be checked:
```
bool ok = token.transfer(to, amount);
require(ok, "TRANSFER_FAILED");
```

However, this approach is inferior because:
- some tokens do not return a boolean
- ABI decoding may revert
- it does not cover all non-standard behaviors

`SafeERC20` handles these edge cases more comprehensively.

## Audit Checklist
### Where to Look
Search everywhere token operations occur:
- `transfer`
- `transferFrom`
- `approve` / `increaseAllowance`
- permit-based flows (indirectly)

## 🚩 Red Flags
- direct calls to `IERC20(token).transfer(...)` without checking return value
- custom “safeTransfer” implementations that do not handle:
  - `false` return values
  - missing return data
- low-level `call` without validating `returndata`

## Impact Assessment

If return values are not checked:
- accounting corruption
- ability to gain protocol benefits without transferring tokens
- broken invariants (shares, collateralization, rewards)

Severity depends on what happens after the transfer:
- minting shares / issuing credit → often High
- simple outbound transfer → may be Medium / Low, but still a bug

## Reporting Guidance

Focus on the integration assumption, not the token.

Example:

> The protocol does not validate the return value of ERC-20 token transfers. When interacting with tokens that return `false` instead of reverting on failure, this may result in accounting corruption and unintended minting of protocol rights without an actual token transfer.

## Knowledge Base Takeaways
- ERC-20 does not guarantee a single failure behavior
- on failure: `revert`, `return false`, or even no return data
- integrators must normalize token behavior
- OpenZeppelin `SafeERC20` is the safest default
