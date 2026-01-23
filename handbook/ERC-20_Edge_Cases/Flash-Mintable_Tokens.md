# Flash-Mintable Tokens
## Summary

Some ERC-20 tokens support **flash minting** - the ability to mint an arbitrarily large amount of tokens within a single transaction, as long as:
- by the end of the transaction
- the full amount
- plus a small fee
- is returned (burned / repaid).

A canonical example is DAI with `flashMint`.

Conceptually, this is:

>A flash loan without an AMM or liquidity pool
>
>(mint → use → repay, all in one call stack)

## Why This Is an Edge Case

Many protocols implicitly assume:

> "To obtain a large token balance, the user must buy or borrow tokens somewhere."

Flash minting breaks this assumption:
- token supply temporarily increases
- the attacker’s balance can become arbitrarily large
- everything happens within a single transaction

📌 If a protocol is not prepared for such instant, temporary balances, serious issues arise.

## Flash Mint vs Flash Loan (Critical Difference)
### Flash Loan
- limited by pool liquidity
- often requires routing or collateral
- depends on external systems (AMMs, lending pools)

### Flash Mint
- limited only by token’s internal rules
- no liquidity pool required
- often allows much larger amounts
- appears more “legitimate” to protocols

➡️ From the protocol’s point of view:

> "This is just a normal ERC-20 balance."

But that balance is **artificial and temporary**.

## Where the Vulnerability Appears
A protocol becomes vulnerable when it:
- treats token balance as **power / weight / rights**
- assumes the balance reflects real economic stake
- does not account for balances that are:
  - huge
  - temporary
  - obtained without real risk

## Common Attack Classes
### 1. Governance / Voting Manipulation

If:
- voting power = `balanceOf`
- no snapshot is used
- no voting delay exists

➡️ flash mint → vote → repay
➡️ proposal passes with no real stake

### 2. Oracle / Price Manipulation

If:
- spot balances are used
- supply-dependent metrics exist
- ratios are computed at call time

➡️ flash mint distorts calculations.

### 3. Reward / Share Inflation

If:
- rewards are distributed proportionally to balance
- without time weighting

➡️ attacker captures a disproportionate share of rewards.

### 4. Limit / Cap Bypass

If limits are expressed in token units:
- `maxDeposit`
- caps
- thresholds

➡️ flash mint allows jumping over limits instantly.

## Why This Is NOT "Just Another Flash Loan"

Because many protocols:
- explicitly defend against flash loans
- do not consider flash minting
- do not expect token supply to change within the same transaction

Especially dangerous when the token is:
- well-known
- a stablecoin
- long-lived and "trusted"

## Protocol Responsibility

Important clarification:
- flash minting is a legitimate token feature
- it is not a token bug
- it is not an exploit by itself

However, if a protocol:
- performs critical actions
- based on instantaneous balances
- without protective mechanisms

➡️ the vulnerability lies in the protocol design.

## Audit Checklist

Ask:
- Can this token be flash-minted?
- Is balanceOf used for:
  - governance?
  - rewards?
  - caps / thresholds?

- Are there protections such as:
  - snapshots?
  - TWAPs?
  - time-weighted balances?
  - delays between deposit and use?

## Typical Mitigations

Design-dependent, but commonly include:
- snapshot-based accounting
- time-weighted voting / rewards
- cooldowns or lockups
- limits on actions rather than balances
- explicit handling of flash-mintable assets

📌 "We don’t expect flash minting" is not a mitigation.

## Knowledge Base Takeaways
- flash mint = instant, temporary liquidity
- balance ≠ economic power
- protocols must not trust instantaneous balances
- especially dangerous for governance, rewards, and oracles
