<div class="cwikmeta">{
"title":"HEADERS",
"related":["/protocol","/protocol/p2p/getheaders"]
}</div>

# Response: Headers ("headers")

Provides a contiguous set of block headers.

## Message Format

| Field | Length | Format | Description |
|--|--|--|--|
| block header count | variable | [variable length integer](/protocol/formats/variable-length-integer) | The number of block headers in this message. |
| block headers | variable | `block_header_count` [block headers with transaction count](#block-header-with-transaction-count-format) | The set of block headers being transmitted, with the block's transaction count. |

No more than 2000 block headers may be sent at one time. Block headers in this array MUST be sequential, ordered by height and without range gaps.

#### Block Header With Transaction Count Format

| Field | Length | Format | Description |
|--|--|--|--|
| block header | 80 bytes | [block header](/protocol/blockchain/block/block-header#block-header-format) | The contents of the block's header. |
| transaction count\* | variable | [variable length integer](/protocol/formats/variable-length-integer) | The number of transactions contained within the block with the preceding header. |

\* The transaction count above is **DEPRECATED** and should be ignored. Nodes are allowed to send 0 regardless of the actual number of transactions in the block.
