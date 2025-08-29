# web3

<h3>There are:</h3>
<ol>
  <li><a href='#commands'>Help Commands</a></li>
  <li><a href='#foundry'>Foundry</a></li>
  <li><a href='#sol'>Solidity</a></li>
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

<h2 align='center' id='researching'><em>Researching</em></h2>
<ul>
  <li><a href='https://owasp.org/www-project-smart-contract-top-10/'>OWASP Smart Contract Top 10</a></li>
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
    </ol>
</ul>
