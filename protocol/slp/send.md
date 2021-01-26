# SEND - Spend Transaction

The following transaction format is used to transfer tokens from one or more token holding UTXO(s) to new token holding UTXO(s).
The UTXOs associated with unspent tokens will be used within the transaction input and, just like the BCH attached to these UTXOs, will be considered totally spent after this transaction is accepted by the blockchain.
Tokens will be assigned to new UTXOs outputs with indexes 1 to 19 as indicated within the OP_RETURN statement.
Any number of additional BCH-only outputs will be allowed.
A BCH-only output can come before token outputs, but a token quantity of 0 must be specified for this output.

**Transaction inputs**: Any number of inputs or content of inputs, in any order, but must include sufficient tokens coming from valid token transactions of matching `token_id`, `token_type` (see [Consensus Rules](/protocol/slp/slp#Consensus-Rules)).

**Transaction outputs**:

| v<sub>out</sub> | ScriptPubKey ("Address") | BCH amount | Implied token amount (base units) |
|-|-|-|-|
| 0 | OP_RETURN<br>&lt;lokad id: 'SLP\x00'&gt; (4 bytes, ascii)<br>&lt;token_type: 1&gt; (1 to 2 byte integer)<br>&lt;transaction_type: 'SEND'&gt; (4 bytes, ascii)<br>&lt;token_id&gt; (32 bytes)<br>&lt;token_output_quantity1&gt; (required, 8 byte integer)<br>&lt;token_output_quantity2&gt; (optional, 8 byte integer)<br>...<br>&lt;token_output_quantity19&gt; (optional, 8 byte integer)<br>| any | 0 |
| 1 | Receiver 1 | any | token_output_quantity1 |
| ... | ... | any | ... |
| N | Receiver N (N = number of token_output_quantities provided) | any | token_output_quantityN |
| ... | Any | any | 0 |
