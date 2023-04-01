# Response: Block Transactions ("blocktxn")

Transmits a group of transactions from a block to a peer.

A `blocktxn` message is sent in response to a [`getblocktxn`](/protocol/network/messages/getblocktxn) message, and must include exactly the set of transactions requested, in the order requested (i.e. in the order they appear in the block).

## Format

| Field | Length | Format | Description |
|--|--|--|--|
| block hash | 32 bytes | bytes | The hash of the block that contains the transactions to follow. |
| transaction count | variable | [variable length integer](/protocol/formats/variable-length-integer) | The number of transactions being provided. |
| transactions | variable | `transaction count` [transactions](/protocol/blockchain/transaction) | The transactions, in order, serialized as though in a [`tx`](/protocol/network/messages/tx) message. |
