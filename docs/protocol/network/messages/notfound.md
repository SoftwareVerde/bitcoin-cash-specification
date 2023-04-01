# Response: Not Found ("notfound")

Indicates that a requested item is not able to be relayed to the requester.

## Message Format

| Field | Length | Format | Description |
|--|--|--|--|
| inventory count | variable | [variable length integer](/protocol/formats/variable-length-integer) | The number of inventory items in this message. |
| inventory items | &lt;inventory_count&gt; * 36 bytes | &lt;inventory_count&gt; [inventory items](/protocol/network/messages/inv#inventory-item-format) | The set of inventory items that cannot be relayed. |
