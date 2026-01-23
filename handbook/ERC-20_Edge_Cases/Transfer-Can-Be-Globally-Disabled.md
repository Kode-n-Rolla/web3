# Transfers Can Be Globally Disabled (Pause / PoS / Centralized Freeze)
## Summary

Some ERC-20 tokens can globally disable transfers via mechanisms such as:
- `paused == true`
- `transfersEnabled == false`
- special PoS / governance flags
- centralized “emergency stop”

In this state:
- all `transfer` / `transferFrom` calls revert
- regardless of sender, receiver, or amount

This is similar to blacklisting, but **stronger**:

> not "this address is blocked”, but “no one can transfer".

## Why This Exists

Common, legitimate reasons include:
- migrations
- upgrades
- regulatory or compliance actions
- incident response / hacks
- PoS-related mechanics

📌 This is **token design**, not a token bug.

## Where the Protocol Becomes Vulnerable

A protocol is at risk if it:
- **must** perform transfers to:
  - close positions
  - liquidate
  - return collateral
  - settle obligations

- and has no fallback path when transfers revert

➡️ A single flag in the token can cause a **complete DoS** for that asset.

## Why This Is Not Unlikely

Because:
- control lies with a third party
- the protocol cannot intervene
- the event can happen suddenly
- the token address does not change

This is **counterparty risk**, not a hack.

## Typical Impact
- locked funds
- failed liquidations → bad debt
- broken settlement flows
- protocol insolvency risk
- emergency shutdown required

### Severity
- often *Medium*
- can be High if the token is system-critical

## Audit Checklist

Ask:
- Can the token be paused globally?
- Is there an admin / governance switch?
- Does the protocol have:
  - graceful failure paths?
  - escrow mechanisms?
  - pull-based withdrawals?

- What happens if every transfer always reverts?

## Short Conclusion
- transfers can be globally disabled
- this is an external, uncontrollable risk
- if the protocol must transfer → DoS is possible
- this is counterparty / design risk, not a token bug
