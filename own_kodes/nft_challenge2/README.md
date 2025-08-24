# LessonTwelve – Cyfrin Foundry Advanced Challenge

This repository contains my solution for **Lesson Twelve** from the [Cyfrin Foundry Advanced Course](https://updraft.cyfrin.io/courses/advanced-foundry).  
The challenge contract is deployed on Sepolia:  
👉 [Etherscan link](https://sepolia.etherscan.io/address/0xe5760847db2f10A74Fc575B4803df5fe129811C1#code)

---

## 🎯 Challenge Description

The core of the challenge is to find a `uint128` value (`numberr`) such that calling `hellFunc(numberr)` **reverts**.  
If `hellFunc` reverts, the execution falls into the `catch` branch, which rewards the solver with an NFT:

```solidity
try i_hellContract.hellFunc(numberr) returns (uint256) {
    revert LessonTwelve__AHAHAHAHAHA();
} catch {
    _updateAndRewardSolver(yourTwitterHandle);
}
```
To solve the challenge, we must:
<ol>
  <li>Discover such a number via fuzzing.</li>
  <li>Deploy our own solver contract that matches the expected interface:</li>
    <ul>
      <li>function getNumberr() external view returns (uint128)</li>
      <li>function getOwner() external view returns (address)</li>
    </ul>
  <li>Call solveChallenge(address exploitContract, string memory twitterHandle) from the solver’s EOA.</li>
</ol>

## 📂 Project Structure
```
src/
  12-Lesson.sol            # Challenge contract
  12-LessonHelper.sol      # Helper contract with hellFunc
  ...And other files from
  ...target contract
  SolverContract.sol       # Minimal solver card
test/
  FuzzHellFunc.t.sol       # Fuzzing test to discover reverting number
script/
  DeployLesson.s.sol       # Deployment script for LessonTwelve
  SolveWith99.s.sol        # Solve script using discovered number
  DirectAttack.s.sol       # Direct solve attempt (POC)

```

## ⚙️ Setup

<ol>
  <li>Initialize a new Foundry project:</li>
    <pre><code>forge init</code></pre>
  <li>Copy challenge contracts into <code>src/</code></li>
  <li>Add this repository’s files into <code>src/</code>, <code>test/</code>, and <code>script/</code>.</li>
  <li>Update <code>foundry.toml</code> to enable dotenv integration, then export variables:</li>
    <pre><code>source .env</code></pre>
</ol>

## 🧪 Step 1: Fuzzing hellFunc

Run the fuzzing test:
<pre><code>forge test --mt testFuzz_FindRevertingNumber -vvvv</code></pre>

Look for log entries showing:
<code>panic: arithmetic underflow or overflow (0x11)</code>

This indicates a revert has been triggered.
The logs will also show the exact number that caused the revert.

## ⛓ Step 2: Local Chain Setup

Start a local chain with Anvil:
<pre><code>anvil</code></pre>

Save two private keys and your RPC URL into .env:
<pre>
PRIVATE_KEY=0x...
ATTACKER_PRIVATE_KEY=0x...
RPC_URL=http://127.0.0.1:8545
</pre>

## 🚀 Step 3: Deploy LessonTwelve

Deploy the challenge contract to your local network:
<pre><code>forge script script/DeployLesson.s.sol:DeployLesson --rpc-url $RPC_URL --broadcast</code></pre>

Save the deployed lesson address into .env as:
<pre>LESSON_ADDRESS=0x...</pre>

## 🛠 Step 4: Test Solve with Discovered Number

Run the solve script using the number found during fuzzing (example: 99):
<pre><code>forge script script/SolveWith99.s.sol:SolveWith99 --rpc-url $RPC_URL --broadcast -vv</code></pre>

Expected:
<ul>
  <li>You may see <code>call to non-contract address</code> — this is normal if the FCN address used in deployment was not a contract.
</li>
  <li>It confirms that the revert number was correct, since execution reached the <code>_updateAndRewardSolver</code> step.</li>
</ul>

## ⚡ Step 5: Direct Attack POC

Finally, run the direct attack script:
<pre><code>forge script script/DirectAttack.s.sol:DirectAttack --rpc-url $RPC_URL --broadcast -vvv</code></pre>

This demonstrates the complete solve flow: deploying a solver card and solving the challenge in one shot.

## 🤚Hands-on
Now all that`s should to do is deploy the <code>SolverContract.sol</code> to Sepolia Network and solve the challenge!

## ✅ Summary

<ul>
  <li>Fuzz <code>hellFunc</code> → find a reverting <code>uint128</code> (e.g., <code>99</code>).</li>
  <li>Deploy a minimal solver contract with <code>getNumberr</code> and <code>getOwner</code>.</li>
  <li>Call <code>solveChallenge</code> from the solver EOA.</li>
  <li>NFT is awarded if the FCN registry is a valid contract.</li>
</ul>
