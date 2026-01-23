# No Return Values (ERC-20 Without `bool` Returns)
## Summary

In the “canonical” ERC-20 interface, token operations typically return a boolean:
- `transfer(...) returns (bool)`
- `transferFrom(...) returns (bool)`
- `approve(...) returns (bool)`

However, some widely used tokens return no value at all (no return data).
A well-known example is USDT, whose `transfer`, `transferFrom`, and `approve` historically did not return a boolean.

This creates integration risks when protocols expect a boolean return value.

## How This Breaks Protocols (Mechanics)

A common vulnerable interface:
```
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}
```

If the real token implementation returns no data, then a call like:
```
bool ok = token.transfer(to, amount);
```

causes Solidity to:
- expect 32 bytes of return data (for bool)
- receive 0 bytes
- revert during ABI decoding

As a result:
- the token operation may have actually executed (or not - irrelevant)
- the protocol still reverts
- the entire execution flow breaks

## Impact
### 🔴 Possible Consequences

1. Complete DoS for token operations
- deposits, withdrawals, repayments, claims become impossible

2. Stuck funds
- the protocol may already hold the token
- but cannot transfer it back due to decoding reverts

3. Upgrade / Governance Risk
- today: whitelist contains “well-behaved” tokens
- tomorrow: a historically non-standard token is added
- system breaks without an obvious root cause

Severity depends on context, but is often Medium or High if the token is important or widely used.

## Standard Mitigation - Why `SafeERC20` Exists
### ✅ OpenZeppelin `SafeERC20` Is the Correct Solution

`SafeERC20` performs a low-level call and treats both cases as success:
- token returns `true`
- token returns no data, but the call does not revert

It also:
- bubbles up token reverts
- converts `return false` into a revert

Effectively, it normalizes ERC-20 behavior:

| Token behavior  | SafeERC20  |
| --------------- | ---------- |
| returns `true`  | ✅          |
| returns nothing | ✅          |
| reverts         | ✅          |
| returns `false` | ❌ → revert |

📌 In practice, this means edge cases #3 and #5 are often grouped as:
"Non-standard ERC-20 return values (false / no return data"

## Audit Checklist - Where to Look

Search for direct token calls:
- `IERC20(token).transfer(...)`
- `IERC20(token).transferFrom(...)`
- `IERC20(token).approve(...)`

Verify:
- is `SafeERC20` used?
- is a boolean decoded directly?

## 🚩 Red Flags
- custom “safeTransfer” implementations without handling empty `returndata`
- interfaces expecting `returns (bool)` with known no-return tokens (e.g., USDT)
- claims of “USDT support” without `SafeERC20`

## The Problem Can Exist Even Without Interfaces
### Scenario A - Low-Level Call + Boolean Decode
```
(bool success, bytes memory data) = token.call(...);
require(success);
bool ok = abi.decode(data, (bool)); // ❌ data may be empty
```

If `data.length == 0` → `abi.decode` reverts.
Same issue, just without an interface.

### Scenario B - Hidden Helper / Wrapper

You may not see the interface directly, but somewhere in the codebase exists:
- `TokenUtils.transfer(...)`
- `ERC20Utils.safeTransfer(...)`
- a custom transfer helper

If it decodes `bool` without checking `data.length`, the DoS remains.

## When the Problem Actually Disappears
### Scenario C - Accept Empty Return Data

If the protocol:
- checks `success`
- treats empty `returndata` as success
- only decodes when data exists

➡️ no-return tokens work correctly.

This is exactly what OpenZeppelin SafeERC20 does:
- `success == true`
- and (`data.length == 0 or `data == true`)

## Related Non-Interface Pitfalls (Context)

Other issues that may appear “without interfaces”:
- token returns malformed data (not `bool`, wrong size)
- token returns `false` but data is ignored
- token reverts with custom errors mishandled by the protocol
- proxy tokens changing behavior after upgrades

But this specific edge case is almost always about:
> interpreting `returndata` as `bool` when no data exists.

## Practical Audit Rule

Don’t ask:
❌ "Is an interface used?"

Ask instead:
✅ "Is there any `abi.decode(..., (bool))` or `bool ok = transfer(...)` without `SafeERC20`?"

If yes → no-return tokens can break the flow.

## Why `require(success)` Is Not Enough
```
(bool success, ) = token.call(...);
require(success);
```
What This Guarantees
- the EVM call did not revert

What This Does NOT Guarantee
- that a transfer happened
- that tokens moved
- that the token did not return `false`
- that balances changed
- that protocol expectations were met

## Concrete Failure Scenarios
### 1. Token Returns false
```
function transfer(...) returns (bool) {
    return false;
}
```

Result:
```
success = true
```
```
require(success); // passes
```

➡️ protocol treats a failed transfer as successful.

### 2. Token Returns Nothing (USDT-style)
```
function transfer(...) { }
```

Result:
```
success = true
data = empty
```
```
require(success); // passes
```

➡️ no confirmation that anything happened.

### 3. Fee-on-Transfer / Rebasing Token
- call succeeds
- balances change unexpectedly
- `success == true`

➡️ accounting breaks silently.

## Why This Is a Vulnerability

Because:
- security ≠ "no revert"
- it leads to:
  - silent failures
  - inconsistent accounting
  - free mint / free credit
  - downstream DoS

This is a quiet bug:
- no revert
- no signal
- system degrades internally

## Minimal Safe Pattern (If Not Using SafeERC20)
### ✅ Recommended - `SafeERC20`
```
token.safeTransfer(to, amount);
```
### ⚠️ Manual Handling (If Absolutely Necessary)
```
(bool success, bytes memory data) = token.call(...);
require(success, "TOKEN_CALL_FAILED");
if (data.length > 0) {
    require(abi.decode(data, (bool)), "TOKEN_OP_FAILED");
}
```

Handles:
- `return false`
- no return data
- revert

## Mental Table
| Case         | success | data            |
| ------------ | ------- | --------------- |
| No return    | true    | empty           |
| return false | true    | encoded `false` |
| revert       | false   | revert reason   |


Example:

> The protocol relies solely on the success flag of a low-level token call and does not validate return data. Token operations that return false or no data may be treated as successful, leading to accounting inconsistencies or denial-of-service scenarios.

## Knowledge Base Takeaways
- ERC-20 in practice ≠ ERC-20 by interface
- some tokens have no return values
- expecting `bool` may cause decode reverts
- `SafeERC20` is the correct default
- `success ≠ success`
- low-level call ≠ safe call
- ERC-20 behavior is not binary
- `require(success)` is insufficient
