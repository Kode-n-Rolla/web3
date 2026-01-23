# Multiple Token Addresses (Shared Balance / Storage)
## Summary

Some tokens may have **multiple contract addresses** that all affect the **same underlying balance and storage**.

A classic example is TrueUSD (TUSD), where:
- multiple contracts exist
- calling `transfer` on different addresses
- modifies the same user balance

### Key idea:
You cannot assume that a token’s balance changes only when `transfer` is called on *one specific token address*.

## Why This Is Possible
### 1. Real Multi-Address Tokens

Some tokens:
- use proxy patterns
- have legacy + new contracts
- support upgrades or migrations
- expose facade / router contracts

Result:
- multiple addresses
- single shared storage

### 2. Wrapper Contracts (More General and More Dangerous)

Even if a token itself is perfectly standard, anyone can deploy a wrapper that forwards calls to the real token.

Conceptual example:
```
contract DaiWrapper {
    IERC20 dai;

    function transfer(address to, uint256 amount) external {
        dai.transferFrom(msg.sender, to, amount);
    }
}
```

From the protocol’s perspective:
- the user interacts with **not DAI**
- but the **DAI balance changes**

📌 At the EVM level, this is **fundamentally indistinguishable** from direct interaction.

## Where the Vulnerability Comes From
The vulnerability appears when a protocol:
- assumes the token address is unique
- uses the token address as a:
  - security flag
  - accounting key
  - "transfer already happened" marker
  - limiter for repeated operations

### Example of Unsafe Logic
```
require(!used[tokenAddress], "Already transferred");
used[tokenAddress] = true;
token.transfer(...);
```

➡️ A wrapper contract bypasses this restriction entirely.

## Why This Is Dangerous (Impact)
### 🔴 Classes of Issues
**1. Bypass of Security Controls**
- "one-time transfer" limits
- token-address-based blacklists
- rate limiting
- anti-reentrancy logic keyed by token address

**2. Invariant Violations**

If the system assumes:

> "Balances only change when we call transfer on this address"

That assumption breaks immediately in the presence of wrappers.

**3. Accounting Desynchronization**
- protocol believes “nothing happened”
- token balance has already changed
- internal accounting ≠ reality

## Important Clarification: This Is NOT About “Blocking Wrappers”

You cannot prevent wrappers:
- the ecosystem is permissionless
- anyone can deploy a forwarding contract
- the EVM provides no way to distinguish a “real token” from a proxy

➡️ Any design relying on token-address uniqueness is fragile by construction.

## Where This Edge Case Matters Most

This is not universal, but critical for:
- protocols with custom accounting
- anti-abuse logic
- systems enforcing “one-time” guarantees
- complex bridges
- escrow / settlement systems

## Audit Checklist

Ask yourself:
- Is there logic like:
  - "this token was already transferred"
  - "after a transfer, X must not happen again"
- Is the token address used as a security primitive?
- Is there an assumption that:

> "Balances change only if we call `transfer`"

If yes → **red flag**.

## Correct Mental Model (Key Takeaway)

> A token is not an address.
> 
> A token is state (storage).
> 
> An address is only one of many possible entry points.

## Knowledge Base Takeaways
- token balances may change through multiple contracts
- token address is not a reliable source of truth
- wrapper contracts make this a universal edge case
- any logic based on *token-address assumptions* is unsafe
