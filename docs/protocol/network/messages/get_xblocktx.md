# Request: Get Xthin Block Transactions ("get_xblocktx")

This message is sent to remote peer to request the transactions still needed to reconstruct the block from the mempool after receipt of the previous [`xthinblock`](xthinblock) or [`thinblock`](thinblock) message.
This message should start with the hash of the block that is intended to be reconstructed, followed by a list of short hashes of the transactions still needed.

## Format

| Field | Length | Format | Description |
|--|--|--|--|
| Block hash | 32 Bytes | Bytes | The hash of the block being reconstructed.|
| Short transaction hashes | # of transactions * 8 bytes | vector | The 64-bit hashes of the transactions still needed for block reconstruction.|
