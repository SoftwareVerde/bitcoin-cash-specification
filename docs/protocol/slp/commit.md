# COMMIT - Checksum Commitment Transaction

As previously discussed, a token issuer should make regular commitments of the SHA-256 hash of previous transactions made for this token.
Although this is not part of the consensus rules (commitments may occur outside of the token transaction graph, and commitment data is never used in consensus rules), it allows a user to verify that the issuer is accurately honoring the token's consensus rules.
This increases confidence that tokens will be judged as expected at the time of redemption.

Initial implementations will focus on supporting the consensus-based forms of validation, and so at this time the exact format for the commitment document is not specified.
General expectations of a commitment format should include:

* The committed information will be in regards to only the transactions that exist in the blockchain leading up to and including the block with hash `for_bitcoin_block_hash`.
(If the block is orphaned, users should ignore this commitment.) The chain height of this block will be stored in the integer `block_height` (even though this is redundant, it aids in lookup for light wallets).

* The committed set of SLP information will be hashed using an *ordered* merkle tree (such as [merklix](https://www.deadalnix.me/2016/09/24/introducing-merklix-tree-as-an-unordered-merkle-tree-on-steroid/)) that allows lite clients to obtain short merkle proofs of the presence *or absence* of a given SLP item (presence indicating valid, absence indicating invalid).

* These commitments will thus enable checkpoint based validation, discussed later.
From this set it is also possible to audit the total number of tokens in circulation (tokens issued minus tokens burned) for that block.

* The set items will relate to one specific `token_id`, and might be transactions, or transaction outputs; all, or only unspent.
The set will be carefully chosen to satisfy the above requirements with a minimal size.

**Transaction inputs**: At least one input should use an address controlled by a trusted validator (could be original issuer, or a respected member of the token community) and this input's signed data should include the OP_RETURN output.

**Transaction outputs**:

| v<sub>out</sub> | ScriptPubKey ("Address") | BCH amount |
|--|--|--|
| 0 | OP_RETURN<br>&lt;lokad_id: 'SLP\x00'&gt; (4 bytes, ascii)<br>&lt;token_type: 1&gt; (1 to 2 byte integer)<br>&lt;transaction_type: 'COMMIT'&gt; (6 bytes, ascii)<br>&lt;token_id&gt; (32 bytes)<br>&lt;for_bitcoin_block_hash&gt; (32 bytes)<br>&lt;block_height&gt; (8 byte integer)<br>&lt;token_txn_set_hash&gt; (32 bytes)<br>&lt;txn_set_data_url&gt; (0 to ∞ bytes, ascii) [to be determined] | any |
| ... | Any | any |
