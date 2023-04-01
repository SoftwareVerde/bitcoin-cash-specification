# P2P Network Message

The Bitcoin Cash Peer-to-Peer (P2P) Network protocol is a binary protocol used by Full Nodes and [SPV](/protocol/simple-payment-verification) Nodes, transmitted over TCP/IP.
Individual nodes on the Bitcoin Cash network connect and create a mesh network where each node is indirectly connected to many others via just a couple of hops.
In the original Satoshi implementation of the P2P protocol the design of INV and getdata have been used for propagating transaction data using the rules of the gossip protocol values: forwarding validated transactions to a few peer-nodes who send it to others until the entire network has the transaction.
This emergent behavior of the P2P layer allows fast propagation without undue strain on any individual node.

The P2P protocol is designed around messages.
Each message is separate and self-contained.
Nodes should be tolerant of message-types they do not understand.
It is best to simply ignore those.

Generally speaking, each message is an event that the node can choose to respond to.
Events can be notifications of new data (transactions/blocks/etc), requests for such data to be sent, or the sending of the data itself.
In some specific cases a message can indicate the rejection of another message, though this is optional and should not be relied upon.

These design decisions were made with consideration to communication with untrusted/uncooperative partners.

*Developer Notes: A common message strategy is to wait for any message that provides the required data (with a timeout), and then separately issue the request in a retry loop to multiple peers.*

## Message Format

The P2P network has a variety of message types.
All P2P messages follow a binary format with the following structure:

| Field | Length | Format | Description |
|--|--|--|--|
| net magic | 4 bytes | byte array<sup>[(BE)](/protocol/misc/endian/big)</sup> | See [net magic](#net-magic). |
| command string | 12 bytes | string<sup>[(BE)](/protocol/misc/endian/big)</sup> | See [command string](#command-string).
| payload byte count | 4 bytes | unsigned integer<sup>[(LE)](/protocol/misc/endian/little)</sup> | The size of the payload.  The total max size of any message is `268,435,456` bytes (256 MiB), and the header for a message is always 24 bytes, therefore the max value of the payload byte count is `268,435,432` bytes, while the min value is zero (indicating no additional payload). |
| payload checksum | 4 bytes | byte array<sup>[(BE)](/protocol/misc/endian/big)</sup> | The message checksum is the first 4 bytes of a double-sha256 hash of the payload. |
| payload | variable | message-specific | See [message types](#message-types) for links to message-specific page, which describe the payload for each message. |

See [Example Message](#example-message) for a concrete example of this with a message that does not contain an extended payload.

### Net Magic

The network identifier is used to separate blockchains and test networks.
This reduces unnecessary load on peers, allowing them to rapidly ban nodes rather then forcing the peer to do a blockchain analysis before banning or disconnecting.
For Bitcoin Cash main net, the `net magic` field is always `0xE3E1F3E8` (the ASCII string, "cash", with each byte's highest bit set).
Any message received that does not begin with the `net magic` is invalid.

The `net magic` is designed to be unlikely to occur in normal data--the characters are rarely used upper ASCII, are not valid as UTF-8, and produce a large 32-bit integer with any alignment.

### Command String

The `command string` is a fixed-length 12 byte ASCII string.
Commands may not be longer than 12 bytes.
Commands that are shorter than 12 bytes are right-padded with null bytes (`0x00`).
The command string is used to determine the type of message being transmitted.
Messages with an unrecognized `command string` are ignored by most implementations but may result in a ban by implementations that diverge from the Satoshi-client defacto standard.

### Message Types

#### Announcements
| Command String | Synopsis |
| -- | -- |
| [filteradd](/protocol/network/messages/filteradd) | *Adds a single item into an installed filter* |
| [filterclear](/protocol/network/messages/filterclear) | *Removes an installed filter* |
| [filterload](/protocol/network/messages/filterload) | *Inserts a transaction and merkle block filter into the peer* |
| [inv](/protocol/network/messages/inv) | *Notifies peers about the existence of some information (generally a block or transaction)* |
| [dsproof-beta](/protocol/network/messages/dsproof-beta) | *Informs participants of an attempt to double spend* |

#### Requests
| Command String | Synopsis |
| -- | -- |
| [feefilter](/protocol/network/messages/feefilter) | *Requests that transactions without sufficient fees are not relayed* |
| [getaddr](/protocol/network/messages/getaddr) | *Requests a list of active peers* |
| [getblocks](/protocol/network/messages/getblocks) | *Requests block hash identifiers* |
| [getdata](/protocol/network/messages/getdata) | *Requests information from a peer* |
| [getheaders](/protocol/network/messages/getheaders) | *Requests block headers from a peer*  |
| [ping](/protocol/network/messages/ping) | *Requests a confirmation (pong) that the peer is still active* |
| [sendheaders](/protocol/network/messages/sendheaders) | *Requests that new blocks are sent as headers instead of hashes* |
| [version](/protocol/network/messages/version) | *Describes peer capabilities, particularly through the [Services Bitfield](/protocol/network/messages/version#services-bitfield)* |
| [mempool](/protocol/network/messages/mempool) | *Request mempool contents* |

#### Responses

| Command String | Synopsis |
| -- | -- |
| [addr](/protocol/network/messages/addr) | *Provides a peer with the addresses of other peers* |
| [block](/protocol/network/messages/block) | *Provides the contents of a block* |
| [headers](/protocol/network/messages/headers) | *Provides a set of block headers (unsolicited or GETHEADERS response)* |
| [notfound](/protocol/network/messages/notfound) | *Indicates that a requested resource could not be relayed* |
| [merkleblock](/protocol/network/messages/merkleblock) | *Provides a provable subset of a block's transactions, as filtered by FILTERADD* |
| [pong](/protocol/network/messages/pong) | *Reply to a ping message* |
| [reject](/protocol/network/messages/reject) | *Response by well-behaved clients if a message cannot be handled* |
| [tx](/protocol/network/messages/tx) | *Provides a transaction* |
| [verack](/protocol/network/messages/verack) | *Response to a [version](/protocol/network/messages/version) message* |

#### Compact Blocks

Compact blocks, defined in [BIP-152](/protocol/forks/bip-0152), seek to minimize the amount of data transferred when a block is mined by taking advantage of the fact that peers often already have most, if not all, of the transactions in a new block.

| Command String | Synopsis |
| -- | -- |
| [sendcmpct](/protocol/network/messages/sendcmpct) | *Indicates that this node supports the Compact Block protocol.* |
| [cmpctblock](/protocol/network/messages/cmpctblock) | *Announces and provides abbreviated contents of a block.* |
| [getblocktxn](/protocol/network/messages/getblocktxn) | *Requests additional transactions from a given block.* |
| [blocktxn](/protocol/network/messages/blocktxn) | *Returns requests transactions contained within a block (in response to [getblocktxn](/protocol/network/messages/getblocktxn).* |

#### Other Message Types (Extensions)

| Command String | Synopsis | Supported Implementations
| -- | -- | -- |
| **XVersion:** [xupdate](/protocol/network/messages/xupdate)  | *Communicates a change in peer capabilities.* | BCHUnlimited |
| **XVersion:** [xversion](/protocol/network/messages/xversion) | *Describes peer capabilities in an extensible manner.* | BCHUnlimited |
| **XVersion:** [xverack](/protocol/network/messages/xverack) | *Response to an [xversion](/protocol/network/messages/xversion) message.* | BCHUnlimited |
| **XThin:** [get_xblocktx](/protocol/network/messages/get_xblocktx) | *Request unknown transactions from a block.* | BCHUnlimited |
| **XThin:** [get_xthin](/protocol/network/messages/get_xthin) | *Request a previously announced xthin block from the announcing peer.* | BCHUnlimited |
| **XThin:** [thinblock](/protocol/network/messages/thinblock) | *A description of a block including full transactions only when it is known that the peer does not have them.* | BCHUnlimited |
| **XThin:** [xthinblock](/protocol/network/messages/xthinblock) | *A description of a block including full transactions only when it is known that the peer does not have them.  Uses truncated hashes to minimize data transfer* | BCHUnlimited |
| **XThin:** [xblocktx](/protocol/network/messages/xblocktx) | *Provides a set of a transactions contained within a block (in response to [get_xblocktx](/protocol/network/messages/get_xblocktx)).* | BCHUnlimited |

## Example message

The below segments, when concatenated in order, create a sample [verack](/protocol/network/messages/verack) message.

| Label | Sample Value (Hexadecimal Representation) |
|-------|------|
| Net Magic<sup>[(BE)](/protocol/misc/endian/little)</sup> | `E3E1F3E8` |
| Command String ("verack")<sup>[(BE)](/protocol/misc/endian/big)</sup> | `76657261636B000000000000` |
| Payload Byte Count<sup>[(LE)](/protocol/misc/endian/little)</sup> | `00000000` |
| Payload Checksum<sup>[(LE)](/protocol/misc/endian/little)</sup> |  `5DF6E0E2` |

Below is the full, concatenated sample message (in hexadecimal):

`E3E1F3E876657261636B000000000000000000005DF6E0E2`

# Node Specific Behavior

## Bitcoin Unlimited

### Payload Checksum

Bitcoin Unlimited does not validate the message checksum since messages are sent via TCP which has its own checksum paradigm.
