# Tokens with Callbacks (ERC-777 & Similar)

## Summary

Some tokens execute external calls during `transfer` or `transferFrom`.
In such cases, a token transfer is not just a balance update, but a potential control-flow transfer.
```
token.transfer(to, amount);
```

This operation may trigger:
- an external call
- execution of untrusted code
- reentrancy into the protocol

The most well-known example is ERC-777, but the issue is not specific to ERC-777.
Any token that implements callbacks introduces the same risk.

## How the Issue Arises

In tokens with callbacks:
- code of the sender or receiver may be executed
- callbacks may occur:
  - before balances are updated
  - after balances are updated
- the exact behavior is not strictly standardized

As a result, during `transfer`:
- the protocol temporarily loses execution control
- its internal state may be observed or used while inconsistent

## Core Risk

If a protocol:
- accepts arbitrary ERC-20 tokens
- performs `token.transfer(...)`
- before updating its own state

➡️ a callback may:
- reenter the same function
- call a different public function
- observe protocol state in a partially updated form

This enables classic reentrancy, including:
- read-only reentrancy
- cross-function reentrancy
- invariant-breaking reentrancy

## Important Clarification

A very common misconception:

> "We only use ERC-20, not ERC-777."

❌ This is incorrect.

If tokens are arbitrary:
- they may appear ERC-20 compliant
- but still execute callbacks internally
- or be proxied / upgraded in the future

> You cannot rely on the declared standard - you can only rely on runtime behavior.

## Potential Attack Vectors
### 1. Reentrancy Before State Update

If execution order is:
```
token.transfer(user, amount); // ⚠️ callback here
balances[user] -= amount;
```

An attacker can:
- receive the callback
- reenter the function
- interact while the balance is still unchanged

### 2. Reentrancy After Transfer but Before Accounting
```
token.transfer(user, amount);   // balances updated
totalDeposits -= amount;        // not updated yet
```

A callback can:
- observe inconsistent state
- break invariants
- influence rewards, pricing, or share logic

### 3. Cross-Function Reentrancy

The callback:
- does not reenter the same function
- instead calls another public function
- that assumes a stable protocol state

This scenario is extremely common and often underestimated.

## Where This Is Most Critical

Especially dangerous in:
- vaults
- staking protocols
- lending / borrowing systems
- bridges
- adapters
- protocol routers

Anywhere with:
- external calls
- internal accounting
- assumptions about execution order

## Audit Checklist
### Key Questions
- Are arbitrary tokens accepted?
- Are `transfer` or `transferFrom` used?
- Is there any external call before state updates?
- Are functions protected with:
  - `nonReentrant`
  - checks-effects-interactions (CEI)
  - pull-over-push pattern?

### 🚩 Red Flags
- `token.transfer(...)` at the beginning of a function
- missing nonReentrant
- complex logic after a transfer
- multiple public entrypoints interacting with shared state

## Defensive Models
### Option 1 - Arbitrary Tokens

✔️ Treat every transfer as potentially reentrant
✔️ Apply CEI strictly
✔️ Use `nonReentrant` where appropriate
✔️ Minimize logic after token transfers

### Option 2 - Whitelisted Tokens

✔️ Explicitly document assumptions
✔️ Verify that tokens do not implement callbacks

⚠️ Still consider:
- governance changes
- proxy upgrades
- future token additions

## Reporting Guidance

Focus on the assumption, not the token.

Example:

> The protocol performs token transfers before updating its internal state while accepting arbitrary ERC-20 tokens. This is unsafe when interacting with tokens that implement callbacks (e.g., ERC-777), as it enables reentrancy and invariant-breaking attacks.

## Knowledge Base Takeaways
- Callbacks = control-flow transfer
- `transfer` is not a safe primitive
- ERC-777 is just one example
- Arbitrary tokens → always assume callbacks
- Reentrancy is not limited to `withdraw → withdraw`
