# Response: Block (“block”)

Provides the contents of a block.

## Message Format

| Field | Length | Format | Description |
|--|--|--|--|
| version number | 4 bytes | signed integer | The block format version number. |
| previous block hash | 32 bytes | bytes | The hash of the block preceding this one in the blockchain. |
| merkle root | 32 bytes | bytes | The root hash of the merkle tree comprised of the block's transactions. |
| timestamp | 4 bytes | unix timestamp<sup>[(LE)](/protocol/misc/endian/little)</sup> | The time the block was generated. |
| hash target | 4 bytes | [compressed target](/protocol/blockchain/block/block-header#compressed-target-format) | The target that the hash of this block is expected to satisfy.  See [Target](/protocol/blockchain/proof-of-work#target). |
| nonce | 4 bytes | bytes | Nonce used to update the block hash during mining.  See [Proof of Work](/protocol/blockchain/proof-of-work). |
| transaction count | variable | [variable length integer](/protocol/formats/variable-length-integer) | The number of transactions in the block (and therefore following in this message). |
| transactions | variable | `transaction_count` [transactions](/protocol/network/messages/tx#message-format) | The transactions contained within this block, formatted the same way they are in a [tx](/protocol/network/messages/tx) message. |

