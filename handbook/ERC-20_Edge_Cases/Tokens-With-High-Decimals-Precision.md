# Tokens With High Decimal Precision
## Summary

Not all ERC-20 tokens use 18 decimals.

Common values:
- 18 (ETH, DAI, most tokens)
- 6 (USDC, USDT)

However, ERC-20 does not impose any upper bound on `decimals`.

Example:
- **YAM v2** uses **24 decimals**

### Key Idea
❗ A protocol must not assume `decimals ≤ 18`.

## Why This Becomes a Problem

Many systems:
- hardcode 18-decimal assumptions
- use `1e18` as a universal scale
- cap precision to 18–22 digits implicitly

When interacting with a token using 24 decimals:
- arithmetic overflows may occur
- precision is silently lost
- rounding becomes incorrect
- math operations may revert

## Where Logic Breaks
### 1. Normalization to 18 Decimals

A very common pattern:
```
normalized = amount * 1e18 / (10 ** decimals);
```

If:
- `decimals = 24`
- `amount` is large

➡️ `amount * 1e18` may overflow
➡️ or lose precision during division

### 2. Implicit or Missing Decimal Bounds

Sometimes code assumes:
```
require(decimals <= 18);
```

If this check is missing but assumed:
- silent corruption occurs
- incorrect shares, rewards, or prices are calculated

### 3. Unsafe `uint256` Scaling

Even without overflows:
- precision loss may occur
- especially in:
  - divisions
  - ratios
  - TWAP calculations
  - share minting logic

## Why This Can Be Critical (Impact)
### 🔴 Possible Consequences
- incorrect accounting
- share inflation / deflation
- reward miscalculation
- price mispricing
- denial of service (via overflow or revert)

Severity depends on:
- the role of the token
- where it is used in the system
- whether defensive checks exist

## Why This Is Not Exotic

Because:
- the ERC-20 standard allows it
- tokens with non-standard decimals exist
- arbitrary ERC-20 implies arbitrary decimals

📌 This is not a token bug
📌 This is an unhandled protocol assumption

## Audit Checklist

Ask:
- Is `decimals == 18` assumed anywhere?
- Is `10 ** decimals` used without bounds?
- Is there an upper bound on supported decimals?
- Are overflows checked during scaling?
- Does the protocol accept arbitrary ERC-20 tokens?

## Mitigation Strategies
### Option 1 - Restrict Supported Decimals
```
require(decimals <= 18, "Unsupported decimals");
```

✔️ simple
✔️ safe
❌ reduces composability

### Option 2 - Safe and Correct Normalization
- safe math
- careful scaling order
- intermediate divisions
- explicit handling of precision loss

📌 more complex, but more universal.

## Knowledge Base Takeaways
- ERC-20 does not limit decimals
- tokens may have >18 decimals
- naive scaling breaks accounting
- arbitrary token → arbitrary decimals
- protocols must either restrict or handle this correctly

## Short Conclusion
- 18 decimals is a convention, not a standard
- higher decimals increase precision risks
- especially dangerous in math-heavy systems
- this is a precision edge case, not a transfer one
