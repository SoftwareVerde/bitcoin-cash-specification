<div class="cwikmeta">{
"title":"INV",
"related":["/protocol","/protocol/network/messages/getdata.md","/protocol/network/messages/filterload.md","/protocol/network/messages/filterclear.md"]
}</div>

# Announcement: Inventory ("inv")

Notifies peers about the existence of some information (block or transaction).

Based on selected services in the [`version`](/protocol/network/messages/version) message, inventory messages may not be sent.

If a bloom filter has been sent to this node via [`filterload`](/protocol/network/messages/filterload), a transaction inventory will only be sent for transactions that match the bloom filter.

## Message Format

| Field | Length | Format | Description |
|--|--|--|--|
| inventory count | variable | [variable length integer](/protocol/formats/variable-length-integer) | The number of inventory items in this message. |
| inventory items | `inventory_count` * 36 bytes | `inventory_count` [inventory items](#inventory-item-format) | The set of inventory items being transmitted. Up to 50,000 inventory items can be sent in a single inventory message.|

NOTE: Since a block header is a relatively small data structure, and block propagation speed is an important network metric, a peer may send [`headers`](/protocol/network/messages/headers) messages in place of inventory messages when a block arrives.  This behavior can be requested using the [`sendheaders`](/protocol/network/messages/sendheaders) message.

#### Inventory Item Format

| Field | Length | Format | Description |
|--|--|--|--|
| type | 4 bytes | [inventory type](#inventory-types)<sup>[(LE)](/protocol/misc/endian/little)</sup> | Indicates what the following hash represents. |
| item hash | 32 bytes | bytes<sup>[(LE)](/protocol/misc/endian/little)</sup> | The [hash](/protocol/blockchain/hash) that identifies the item. |

#### Inventory Types
The type of the object that is available.

| Type | Value|
|------|------|
|   0x0001  |  Transaction |
|   0x0002  |  Block |
|   0x0003  |  Filtered Block (partial block with merkle proof)
|   0x0004  |  Compact block
|   0x0005  |  Xthin block (Bitcoin Unlimited)
|   0x0006  |  Graphene Block (Bitcoin Unlimited)
|   0x94A0  | [Double Spend Proof - Beta](/protocol/network/messages/dsproof-beta) |

Implementations: [C++](https://github.com/BitcoinUnlimited/BitcoinUnlimited/blob/eb264e627e231f7219e60eef41b4e37cc52d6d9d/src/protocol.h#L477)
