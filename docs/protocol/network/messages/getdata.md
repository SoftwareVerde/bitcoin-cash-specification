<div class="cwikmeta">{
"title":"GETDATA",
"related":["/protocol","/protocol/p2p/inv"]
}</div>

# Request: Get Data (“getdata”)

Requests information (generally previously announced via an [`inv`](/protocol/network/messages/inv) message) from a peer.
As such, a getdata request carries the same general format as an inventory message and is used to request any items that the node was previously unaware.

## Message Format

| Field | Length | Format | Description |
|--|--|--|--|
| inventory count | variable | [variable length integer](/protocol/formats/variable-length-integer) | The number of inventory items being requested in this message. |
| inventory items | `inventory_count` * 36 bytes | `inventory_count` [inventory items](/protocol/network/messages/inv#inventory-item-format) | The set of inventory items being requested. |

## Server Implementations 

[Bitcoin Unlimited](https://github.com/BitcoinUnlimited/BitcoinUnlimited/blob/bucash1.7.0.0/src/net_processing.cpp#L1021)

## Client Implementations