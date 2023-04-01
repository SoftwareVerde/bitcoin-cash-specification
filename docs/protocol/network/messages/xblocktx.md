# Response: Xthin Block Transactions ("xblocktx")

This message delivers the transactions specified in the previous [`get_xblocktx`](get_xblocktx) message to the remote peer.
This message starts with the hash of the block being reconstructed, followed by a list of transactions requested.

## Format

| Field | Length | Format | Description |
|--|--|--|--|
| Block hash | 32 Bytes | Bytes | The hash of the block being reconstructed.|
| Transactions | variable | vector | The transactions still needed for block reconstruction.|
