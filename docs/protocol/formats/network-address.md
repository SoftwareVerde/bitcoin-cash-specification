# Network Address

Specifies the basic information necessary to connect to a peer node.

## Format

| Field | Length | Format | Description |
|--|--|--|--|
| timestamp\* | 4 bytes | unix timestamp<sup>[(LE)](/protocol/misc/endian/little)</sup> | Last known time (in seconds) that the peer was known to be "live." |
| services | 8 bytes | bitfield<sup>[(LE)](/protocol/misc/endian/little)</sup> | The services this node supports.  See [Services Bitfield](/protocol/network/messages/version#services-bitfield). |
| IP address | 16 bytes | [ip address](#ip-address-format) | The IP (v4 or v6) address used to connect to the peer. |
| port | 2 bytes | unsigned integer<sup>[(BE)](/protocol/misc/endian/little)</sup> | The port used to the connect to the peer. |

\* *timestamp* is not included where network addresses appear in the [version](/protocol/network/messages/version) message format

#### IP Address Format

A single format is used to specify IPv4 and IPv6 addresses, [IPv4-mapped IPv6 addresses](https://en.wikipedia.org/wiki/IPv6#IPv4-mapped_IPv6_addresses):

 * If the intended address is IPv6, the standard "network byte order" or [big-endian](/protocol/misc/endian/big) byte encoding is used.
 * If the intended address is IPv4, the first 12 bytes are set to 0x00000000000000000000FFFF, followed by the big-endian IPv4 address.
