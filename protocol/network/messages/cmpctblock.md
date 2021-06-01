# Announcement: Compact Block ("cmpctblock")

Transmits a compact block to a peer.

This message is automatically sent to "high bandwidth relaying" peers, or in response to a [`getdata`](/protocol/network/messages/getdata) request specifying the [compact block inventory type](/protocol/network/messages/inv#inventory-types) and block hash.

## Format

The below format is referred to in [BIP-152](/protocol/forks/bip-0152) as `HeaderAndShortIDs`.

| Field | Length | Format | Description |
|--|--|--|--|
| header | 80 bytes | [block header](/protocol/blockchain/block/block-header) | The header of the block being sent. |
| nonce | 4 bytes | unsigned integer<sup>[(LE)](/protocol/misc/endian/little)</sup> | A nonce used in the calculation of the short transaction IDs to follow.  This is generated by the sender and must be unique per block but not necessary per peer. |
| short id count | variable | [variable length integer](/protocol/formats/variable-length-integer) | The number of short transaction IDs to follow.  This will be the number of transaction in the block minus the number of "prefilled" transactions provided at the end of this message. |
| short ids | `short_id_count* 6` bytes | `short_id_count` 6-byte unsigned integers<sup>[(LE)](/protocol/misc/endian/little)</sup> | The list of transactions in the block, referenced by [short transaction IDs](#short-transaction-ids).  This includes every transaction in the block *except* the "prefilled" transactions to follow. |
| prefilled transaction count | variable | [variable length integer](/protocol/formats/variable-length-integer) | The number of prefilled transactions to follow. |
| prefilled transactions | variable | `prefilled_transaction_count` [prefilled transactions](#prefilled-transactions) | The coinbase transaction and any other transactions in the block that the sender believes the peer may be missing. |

### Short Transaction IDs

Short transaction IDs are generated using the following steps:

1. Generate a key, `k`, as the little-endian single-SHA-256 hash of the block header concatenated with the little-endian compact block nonce generated by the sender (i.e. either a new random value or the one received from a peer).
2. Calculate the [SipHash-2-4](https://en.wikipedia.org/wiki/SipHash) of the full transaction ID using `k` as the key.  For implementations that expect two keys, use the first 64-bits of the little-endian hash as `k<sub>0</sub>` and the second 64-bits as `k<sub>1</sub>`.
3. Drop the 2 most-significant bytes of the SipHash output to get the 6-byte short transaction ID.

For more information about the design of these short IDs, see [BIP-152:Short transaction ID calculation](/protocol/forks/bip-0152#short-transaction-id-calculation).
For additional details on how the recipient should handle this message, see [reconstructing the block](#reconstructing-the-block).

### Prefilled Transactions

Prefilled transactions specify the full transaction data for transactions that are not expected to already be known by the recipient.
The coinbase transaction is always such a transaction, while others may be included at the sender's discretion.
The format is as follows:

| Field | Length | Format | Description |
|--|--|--|--|
| index | variable | [variable length integer](/protocol/formats/variable-length-integer) | The ["differentially encoded"](#differentially-encoded-indexes) position of the transaction with in the block. |
| transaction | variable | [transaction](/protocol/blockchain/transaction#format) | The full transaction contents, as in a [`tx`](/protocol/network/messages/tx) message. |

## Differentially Encoded Indexes

Where compact-block-related messages reference the indexes of transactions within a block, they use a differential encoding to further minimize the amount of data used.
In such a list of transactions with indexes, each index is interpreted as a relative index from the previous transaction in the list.
That is, if the first transaction has an index of `0`, it is the first transaction in the block (true index `0`).
If the second transaction also has an index of `0`, it is the second transaction in the block (true index `1`).

Generally, if `d<sub>n</sub>` is the differentially encoded index for the `n`-th transaction in a given list, and `t<sub>n</sub>` is that transactions true index within the block, `t<sub>n</sub> = t<sub>n-1</sub> + d<sub>n</sub> + 1`.
Conversely, `d<sub>n</sub> = t<sub>n</sub> - t<sub>n-1</sub> - 1`.

## Reconstructing the Block

Upon receipt of a `cmpctblock` message, the recipient must first determine whether it now has all the transactions needed to reconstruct the block.  First, all prefilled transactions should be processed.  If some transactions are still unknown, the recipient may request then using a [`getblocktxn`](/protocol/network/messages/getblocktxn) message.  Once the recipient has all of the necessary transactions, the block's [merkle tree](/protocol/blockchain/block/merkle-tree) can be re-built by adding the transactions in the order specified by the indexes.  NOTE: since [HF-20181115](/protocol/forks/hf-20181115), [CTOR](/protocol/forks/hf-20181115#canonical-transaction-order) means that this the same order can also be achieved by sorting the transactions by their hashes.

For more information on when `cmpctblock` messages should be sent and how they should be validated, see [BIP-152](/protocol/forks/bip-0152).