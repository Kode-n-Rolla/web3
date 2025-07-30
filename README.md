# web3

<h1>There are</h1>
<ol>
  <li><a href='#commands'>Help Commands</a></li>
  <li><a href='#foundry'>Foundry</a></li>
</ol>

<h2 align='center' id='commands'><em>Help Commands</em></h2>
<ul>
  <li>Interact with blockchain storage</li>
  <pre><code>curl -X POST [RPC_URL] -H "Content-Type: application/json" -d '{"jsonrpc":"2.0", "method":"eth_getStorageAt", "params": ["[CONTRACT_ADDRESS]","[NUM_SLOT-IN-HEX]","latest"],"id":1}'</code></pre>
  Need to change <code>[RPC_UR]</code>, <code>[CONTRACT_ADDRESS]</code>, <code>[NUM_SLOT-IN-HEX]</code>
</ul>

<h2 align='center' id='commands'><em>Foundry</em></h2>
<ol>
  <li><a href='#foundry-cast'>Cast</a></li>
</ol>

<h3 id='foundry-cast'> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <ins>Cast</ins></h3>
<ul>
  <li>hex to decimal</li>
  <pre><code>cast --to-dec [hex]</code></pre>
  <li>hex to string</li>
  <pre><code></code></pre>
</ul>
