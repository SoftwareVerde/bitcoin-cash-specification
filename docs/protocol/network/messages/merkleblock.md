<div class="cwikmeta">{
"title":"MERKLEBLOCK",
"related":["/protocol", "/protocol/p2p/filteradd"]
}</div>

# Response: Merkle Block ("merkleblock")

Provides a block header and partial merkle proof tree to show that the selected transaction [hashes](/protocol/blockchain/hash) exist in the block.

Transactions are selected by honest servers if they match the bloom filter installed by the client.  However, note that servers can omit transactions and this cannot be detected except by receiving a `merkleblock` message from an honest server.

All selected transactions are subsequently sent as separate [`tx`](/protocol/network/messages/tx) messages.  Due to multi-threading on the server, clients should not assume that these transaction messages directly follow the `merkleblock` message.

## Message Format

| Field | Length | Format | Description |
|--|--|--|--|
| block header | 80 bytes | [block header](/protocol/blockchain/block/block-header#block-header-format) | The header of the block. |
| transaction count | 4 bytes | unsigned integer<sup>[(LE)](/protocol/misc/endian/little)</sup> | The number of transactions in the block. |
| filtered transaction count | variable | [variable length integer](/protocol/formats/variable-length-integer) | The number of transactions matching the client's bloom filter. |
| transaction hashes | `transaction_count` * 32 bytes | bytes<sup>[(LE)](/protocol/misc/endian/little)</sup> | The hashes of the full set of transactions in the block, in the the order they appear in the block (i.e. depth-first order with respect to the merkle tree). |
| flag byte count | variable | [variable length integer](/protocol/formats/variable-length-integer) | The number of flags bytes to follow. |
| flag bits | `flag_count` bytes | bytes | Flag bits, collected into bytes (zero-padded to a full byte as necessary) indicating inclusion information with respect to traversal of the partial merkle tree of matches.  See [partial merkle tree flag bits](#partial-merkle-tree-flag-bits). |

#### Partial Merkle Tree Flag Bits

The partial merkle tree flag bits effectively create a variable-width bitfield, indicating which transaction hashes from the block the `merkleblock` message pertains to actually matched the client's bloom filter.
If you picture the merkle tree root at the top, the flag bits represent a top-down yes/no approach to whether the a given branch (or leaf node) of the tree includes any matching transactions.

For full details, see [BIP-37: Partial Merkle Branch Format](/protocol/forks/bip-0037#partial-merkle-branch-format).
