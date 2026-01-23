# Upgradeable Tokens (Mutable Behavior Behind a Stable Address)
## Summary

Some ERC-20 tokens are **upgradeable** - their logic can be changed via a proxy while the token address remains the same.

A canonical example is **USDC**:
- today it behaves like a "standard" ERC-20
- but technically it:
  - can enable fee-on-transfer
  - can introduce callbacks
  - can tighten blacklist / compliance logic
  - can change approve / transfer semantics

### Key idea:
You cannot assume that the current behavior of an upgradeable token is permanent.

## Important Clarification - This Is Not Hypothetical

This is not a theoretical “if they wanted to” risk.

Facts:
- USDC already contains latent features (e.g. fee-on-transfer capability)
- those features are simply disabled
- an upgrade may:
  - enable them
  - change execution order
  - add new revert conditions

➡️ Token behavior can change without changing the token address or interface.

## Where the Protocol Vulnerability Comes From

The vulnerability appears when a protocol:
- is hard-coded against the current behavior of a token
- relies on assumptions like:
  - "USDC is not fee-on-transfer"
  - "USDC does not execute callbacks"
  - "USDC approve always works this way"

- omits defensive mechanisms because the token is considered "safe"

After an upgrade:
- invariants break
- accounting becomes incorrect
- DoS / reentrancy / griefing paths appear
- the protocol breaks without **any change to its own code**

## Why This Is a Dangerous ERC-20 Edge Case

Because:
- the token address does not change
- the ABI remains the same
- interfaces still compile
- but semantics change

📌 This is one of the most dangerous classes of risks:

> Semantic upgrade without interface change

## Where This Is Especially Critical
- lending / borrowing protocols
- vaults
- bridges
- liquidation engines
- AMM adapters
- long-lived protocols

The longer a protocol is expected to live, the higher this risk becomes.

## Common Failure Scenarios
### 1. Fee-on-Transfer Suddenly Enabled
- deposited amount ≠ received amount
- share inflation
- broken accounting

### 2. Callbacks Introduced
- new reentrancy paths in legacy code
- especially dangerous if nonReentrant was omitted

### 3. New Revert Conditions
- zero-amount transfers
- stricter blacklist logic
- compliance checks

➡️ DoS of critical protocol flows.

## Why "We Trust USDC" Is Not a Valid Argument

From an audit perspective:
- trust ≠ safety
- risk ≠ malicious intent
- even regulatory or compliance changes may require upgrades

The auditor’s question is:

> *What happens to the protocol if the token changes behavior tomorrow without breaking its interface?*

## Audit Checklist

Ask:
- Is the token used via a proxy?
- Is there an upgrade admin?
- Does the token have latent features (fees, callbacks, blacklist)?
- Is the protocol tightly coupled to current token behavior?
- Is balance-delta accounting used?
- Is `nonReentrant` applied where needed?
- Are there graceful failure paths?

## Practical Mitigations (Design-Dependent)
Common defensive approaches:
- write code as if the token were arbitrary
- avoid relying on “known” properties
- consistently use:
  - balance delta accounting
  - `SafeERC20`
  - CEI pattern
 
- document assumptions explicitly
- sometimes: whitelist + clear risk disclosure

📌 Important:
A whitelist **does not eliminate upgrade risk**.

## Knowledge Base Takeaways
- upgradeable token = mutable behavior
- address stability ≠ behavior stability
- latent features are real risks
- protocols must defend against future semantic upgrades
