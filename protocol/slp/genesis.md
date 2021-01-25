# GENESIS - Token Genesis Transaction

This is the first transaction which defines the properties, metadata and initial mint quantity of the token
The token is thereafter uniquely identified by the token genesis transaction hash which is referred to as `token_id`.

`token_type` indicates the SLP sub-protocol:

* 1 - Permissionless Token Type
* 2 - Reserved for Security Token Type
* 3 - Reserved for Voting Token Type
* 4 - Reserved for Ticketing Token Type
* ...

This document specifies the rules and operation of the Permissionless Token Type (1) only.
Tokens of different types cannot be mixed, and so future specifications of other token types will not affect the consensus validity of type 1.

`mint_baton_vout`: Future token supply increases are made possible if the genesis endows a specific transaction output with a "minting baton" that can be passed along and used for future minting (using ['MINT'](/protocol/slp/mint) transactions)
If `mint_baton_vout` is not present or refers to a nonexistent output, then the baton does not exist and the token provably has a one-time issuance.

`decimals`: indicates that 1 token is divisible into 10^`decimals` base units
SLP messages store whole numbers indicating token amounts as measured in the base unit, analogous to how bitcoin transactions store BCH amounts measured in the base unit 'satoshis'
With a token FOO having `decimals` of 6 indicated in the genesis, for example, the quantity 12.53 FOO (as displayed in wallet software) would be represented by 12530000 base units (as 8 bytes, hex 0000000000bf3150)
A `decimals` of 8 would give the same divisibility as bitcoin, whereas 0 would give indivisible tokens.

The genesis transaction includes an initial minting of `initial_token_mint_quantity` base units, placed on the second transaction output (vout=1).

**Transaction inputs**: Any number of inputs or content of inputs, in any order.

**Transaction outputs**:

| v<sub>out</sub> | ScriptPubKey ("Address")| BCH amount| Implied token amount (base units) |
| - | - | - | - |
| 0 | OP_RETURN<br>&lt;lokad_id: 'SLP\x00'&gt; (4 bytes, ascii)<sup>1</sup><br>&lt;token_type: 1&gt; (1 to 2 byte integer)<br>&lt;transaction_type: 'GENESIS'&gt; (7 bytes, ascii)<br>&lt;token_ticker&gt; (0 to ∞ bytes, suggested utf-8)<br>&lt;token_name&gt; (0 to ∞ bytes, suggested utf-8)<br>&lt;token_document_url&gt; (0 to ∞ bytes, suggested ascii)<br>&lt;token_document_hash&gt; (0 bytes or 32 bytes)<br>&lt;decimals&gt; (1 byte in range 0x00-0x09)<br>&lt;mint_baton_vout&gt; (0 bytes, or 1 byte in range 0x02-0xff)<br>&lt;initial_token_mint_quantity&gt; (8 byte integer)<br> | any<sup>2</sup> | 0 |
| 1 | Initial mint receiver | any<sup>2</sup> | initial_token_mint_quantity |
| ... | Any | any<sup>2</sup> | 0 |
| M | (M=mint_baton_vout) Mint baton receiver | any<sup>2</sup> | 0<br>+ 'baton' |
| ... | Any | any<sup>2</sup> | 0 |
You can now import Markdown table code directly using File/Paste table data..
dialog.




<sup>1
The Lokad identifier is registered as the number 0x504c53 (which, when encoded in the 4-byte little-endian format expected for Lokad IDs, gives the ascii string 'SLP\x00')
Inquiries and additional information about the Lokad system of OP_RETURN protocol identifiers can be found at [https://github.com/Lokad/Terab](https://github.com/Lokad/Terab) maintained by Joannes Vermorel.</sup>

<sup>2
SLP does not impose any restrictions on BCH output amounts
Typically however the OP_RETURN output would have 0 BCH (as any BCH sent would be burned), and outputs receiving tokens / mint batons would be sent only the minimal 'dust' amount of 0.00000546 BCH.</sup>
