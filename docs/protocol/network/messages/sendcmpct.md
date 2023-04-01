# Request: Send Compact Blocks ("sendcmpct")

This message notifies the peer that this node support Compact Block Relay.
Node should only send this message after protocol version >= 70014.
This message can indicate the High Bandwidth Relaying mode or Low Bandwidth Relaying mode by setting the `Mode` field.
Upon receipt of this message from the peer, node should announce new block via `cmpctblock` message if `Mode = 1`, or node should announce new block via `inv` or `header` message as defined in BIP-0130.

## Format

| Field | Length | Format | Description |
|--|--|--|--|
| Mode | 1 byte | Integer | 1: High Bandwidth Relaying mode;</br> 0: Low Bandwidth Relaying mode;</br> Other: Invalid |
| Version | 8 bytes | Integer <sup>[(LE)](/protocol/misc/endian/little)</sup> | Must set to 1, otherwise invalid.|
