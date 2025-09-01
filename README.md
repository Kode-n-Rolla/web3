# web3

<h3>There are:</h3>
<ol>
  <li><a href='#commands'>Help Commands</a></li>
  <li><a href='#foundry'>Foundry</a></li>
  <li><a href='#sol'>Solidity</a></li>
  <li><a href=#tools>Tools</a>
  <li><a href='#researching'>Researching</a></li>
</ol>

<h2 align='center' id='commands'><em>Help Commands</em></h2>
<ul>
  <li>Interact with blockchain storage</li>
  <pre><code>curl -X POST [RPC_URL] -H "Content-Type: application/json" -d '{"jsonrpc":"2.0", "method":"eth_getStorageAt", "params": ["[CONTRACT_ADDRESS]","[NUM_SLOT-IN-HEX]","latest"],"id":1}'</code></pre>
  Need to change <code>[RPC_UR]</code>, <code>[CONTRACT_ADDRESS]</code>, <code>[NUM_SLOT-IN-HEX]</code>
</ul>

<h2 align='center' id='foundry'><em>Foundry</em></h2>
<ol>
  <li><a href='#foundry-cast'>Cast</a></li>
  <li><a href='#foundry-forge'>Forge</a></li>
</ol>

<h3 id='foundry-cast'> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <ins>Cast</ins></h3>
<ul>
  <li>hex to decimal</li>
    <pre><code>cast --to-dec [hex]</code></pre>
  <li>hex to string</li>
    <pre><code>cast --abi-decode "myFunc()(string)" 0x00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000014416e79206b696e64206f6620636f6f6b69657321000000000000000000000000</code></pre>
    <code>myFunc()</code> is random name. Guess <code>cast</code> just need (unexisted)function in command.
  <li>keccak256 with string</li>
    <pre><code>cast keccak "..."</code></pre>
  <li>Function signature</li>
    <pre><code>cast sig "func(uint256,address)"</code></pre>
  <li>ABI encode with args</li>
    <pre><code>cast calldata "func(...)" arg1 arg2</code></pre>
  <li>ABI encode without sig, only args</li>
    <pre><code>cast calldata "func(...)" arg1 arg2</code></pre>
  <li>Check storage</li>
    <pre><code>cast storage [CONTRACT_ADDRESS] [NUM_SLOT] --rpc-url [RPC_URL]</code></pre>
  <li>Bytes to string</li>
    <pre><code>cast parse-bytes32-string [TARGET_BYTES]</code></pre>
</ul>

<h3 id='foundry-forge'> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <ins>Forge</ins></h3>
<ul>
  <li>Test</li>
    <ol>
      <li>Test certain function</li>
      <pre><code>forge test --match-test testFunctionName -vvv</code></pre>
      <code>-vvv</code> for deep verbose
    </ol>
  <li>Inspect</li>
    To view storage layout
    <pre><code>forge inspect CONTRACT_NAME storage-layout</code></pre>
</ul>

<h2 align='center' id='sol'><em>Solidity</em></h2>
<ul>
  <li>Compare <code>string</code> type</li>
    <pre><code>keccak256(abi.encodePacked(string1)) == keccak256(abi.encodePacked(string2))</code></pre>
</ul>

<h2 align='center' id='commands'><em>Tools</em></h2>
<ol>
  <li><a href='https://vscodium.com/'>VS Codium</a></li>
    <ul>
      <li><a href='https://github.com/ConsenSysDiligence/vscode-solidity-metrics'>Solidity Metrics extension</a></li>
    </ul>
  <li><a href='https://getfoundry.sh/'>Foundry</a></li>
  <li><a href='https://github.com/AlDanial/cloc'>CLoC</a></li>
</ol>

<h2 align='center' id='researching'><em>Researching</em></h2>
  <li><a href='https://github.com/Cyfrin/security-and-auditing-full-course-s23/blob/main/minimal-onboarding-questions.md'>Minimal Smart Contract Security Review Onboarding</a></li>
 
  <details><summary><a href='https://blog.trailofbits.com/2023/08/14/can-you-pass-the-rekt-test/'>The Rekt Test</a></summary>
    <ol>
      <li>Do you have all actors, roles, and privileges documented?</li>
      <li>Do you keep documentation of all the external services, contracts, and oracles you rely on?</li>
      <li>Do you have a written and tested incident response plan?</li>
      <li>Do you document the best ways to attack your system?</li>
      <li>Do you perform identity verification and background checks on all employees?</li>
      <li>Do you have a team member with security defined in their role?</li>
      <li>Do you require hardware security keys for production systems?</li>
      <li>Does your key management system require multiple humans and physical steps?</li>
      <li>Do you define key invariants for your system and test them on every commit?</li>
      <li>Do you use the best automated tools to discover security issues in your code?</li>
      <li>Do you undergo external audits and maintain a vulnerability disclosure or bug bounty program?</li>
      <li>Have you considered and mitigated avenues for abusing users of your system?</li>
    </ol></details>
  <details><summary><a href='https://github.com/nascentxyz/simple-security-toolkit/blob/main/audit-readiness-checklist.md'>Audit Scoping Details</a></summary>
    <ul>
      <li>Public link code repo, if exist</li>
      <li>How many contracts are in scope?</li>
      <li>Total SLoC for these contracts?</li>
      <li>How many external imports are there?</li>
      <li>How many separate interfaces and struct definitions are there for the contracts within scope?</li>
      <li>Does most of your code generally use composition or inheritance?</li>
      <li>How many external calls?</li>
      <li>What is the overall line coverage percentage provided by your tests?:</li>
      <li>Is there a need to understand a separate part of the codebase / get context in order to audit this part of the protocol?</li>
      <li>If so, please describe required context</li>
      <li>Does it use an oracle?</li>
      <li>Does the token conform to the ERC20 standard?</li>
      <li>Do you expect ERC721, ERC777, FEE-ON-TRANSFER, REBASING or any other non-standard ERC will interact with the smart contracts?</li>
      <li>Are there any novel or unique curve logic or mathematical models?</li>
      <li>Does it use a timelock function?</li>
      <li>Is it an NFT?</li>
      <li>Does it have an AMM?</li>
      <li>Is it a fork of a popular project?</li>
      <li>Does it use rollups?</li>
      <li>Is it multi-chain?</li>
      <li>Does it use a side-chain?</li>
      <li>Describe any specific areas you would like addressed. E.g. Please try to break XYZ."</li>
    </ul></details>
    <details><summary><a href='https://owasp.org/www-project-smart-contract-top-10/'>OWASP Smart Contract Top 10</a></summary>
    <ol>
      <li>Access Control Vulnerabilities</li>
      <li>Price Oracle Manipulation</li>
      <li>Logic Errors</li>
      <li>Lack of Input Validation</li>
      <li>Reentrancy Attacks</li>
      <li>Unchecked External Calls</li>
      <li>Flash Loan Attacks</li>
      <li>Integer Overflow and Underflow</li>
      <li>Insecure Randomness</li>
      <li>Denial of Service (DoS) Attacks</li>
    </ol></details>
