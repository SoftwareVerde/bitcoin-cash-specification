# Request: Get Block Transactions ("getblocktxn")

Requests unknown transactions in a block from a peer.

Upon receiving a [`cmpctblock`](/protocol/network/messages/cmpctblock) message, a node may determine it is still missing some transactions from the recent block, which it can request using a `getblocktxn` message.
A node receiving a `getblocktxn` message, that has recently sent a `cmpctblock` message for the specified block to this peer, must respond with either a [`blocktxn`](/protocol/network/messages/blocktxn) message or a [`block`](/protocol/network/messages/block) message.

## Format

| Field | Length | Format | Description |
|--|--|--|--|
| block hash | 32 bytes | bytes | The hash of the block containing the desired transactions. |
| indexes count | variable | [variable length integer](/protocol/formats/variable-length-integer) | The number of transactions being requested. |
| indexes | variable | `indexes_count` [variable length integers](/protocol/formats/variable-length-integer) | The [differentially encoded indexes](/protocol/network/messages/cmpctblock#differentially-encoded-indexes) of the transactions within the block being requested. |
