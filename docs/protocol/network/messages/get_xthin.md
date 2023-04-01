# Request: Get Xthin Block ("get_xthin")

Request the [`xthinblock`](xthinblock) from the peer that was anoounced via the previous [`inv`](/protocol/network/messages/inv) message.
The message should start with an inventory message that indicates the `xthinblock` requested, followed by the Bloom filter generated from the mempool.
Upon receipt of this request, the peer should loads the attached Bloom filter, creates and responds with `xthinblock`.
If the `xthinblock` cannot be created without hash collisions, the peer may respond with `thinblock` or full blocks.

## Format

| Field | Length | Format | Description |
|--|--|--|--|
| inventory message | variable | inventory message | An inventory message of type MSG_XTHINBLOCK.|
| Bloom filter | varaible | serialized object | A serialized Bloom filter seeded with contents of the mempool.|
