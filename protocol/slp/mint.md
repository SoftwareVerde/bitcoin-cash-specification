# MINT - Extended Minting Transaction

Subsequent minting transactions of `additional_token_quantity` can be performed by spending the "minting baton" UTXO in a special MINT transaction, described here.
Note that this could be done by someone other than the GENESIS issuer, if the baton minting authority had been passed to another address.

As with [GENESIS](/protocol/slp/genesis.md), the MINT allows to end the baton, or further pass on the baton to future mint operations: if `mint_baton_vout` is empty or refers to a nonexistent vout, the transaction is valid but the baton is lost.
This makes it possible to prove end-of-minting capabilities for a token even after several minting events (it is impossible to duplicate this baton as that would require double-spending the transaction output associated with the baton).

**Transaction inputs**: Any number of inputs or content of inputs, in any order, but with required presence of a 'baton' input (see [Consensus Rules](/protocol/slp/slp.md)).

**Transaction outputs**:

| v<sub>out</sub> | ScriptPubKey ("Address") | BCH amount | Implied token amount (base units) |
|-|-|-|-|
| 0 | OP_RETURN<br>&lt; lokad_id: 'SLP\x00'&gt; (4 bytes, ascii)<br>&lt; token_type: 1&gt; (1 to 2 byte integer)<br>&lt; transaction_type: 'MINT'&gt; (4 bytes, ascii)<br>&lt; token_id&gt; (32 bytes)<br>&lt; mint_baton_vout&gt; (0 bytes or 1 byte between 0x02-0xff)<br>&lt; additional_token_quantity&gt; (8 byte integer) | any | 0 |
| 1 | Token mint receiver | any | additional_token_quantity |
| ... | Any | any | 0 |
| M | Mint baton receiver (M=mint_baton_vout) | any | 0 + 'baton' |
| ... | Any | any | 0 |
