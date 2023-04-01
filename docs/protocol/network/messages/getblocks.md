<div class="cwikmeta">{
"title":"GETBLOCKS",
"related":["/protocol","/protocol/network/messages/getdata.md","/protocol/network/messages/getheaders.md"]
}</div>

# Request: Get Blocks (“getblocks”)

Request the sequence of blocks that occur after a specific block.  If the specified block is on the server's most-work chain, the server responds with a set of up to 500 [`inv`](/protocol/network/messages/inv.md) messages identifying the next blocks on that chain.  If the specified block is not on the most-work chain, the server uses block information in the *locator* structure to determine the fork point and provides [`inv`](/protocol/network/messages/inv.md) messages from that point.

## Message Format

| Field | Length | Format | Description |
|--|--|--|--|
| locator | variable | [vector](/protocol/p2p/vector.md) of 32 byte block [hash identifiers](/glossary/hash__identifier.md) | identifies the desired blocks location in the blockchain|
| stop at hash | 32 bytes | bytes | send no more INVs if this hash is encountered



### Locator

See [`getheaders`](/protocol/network/messages/getheaders) for a detailed description of the Locator object.

The response will begin at **the child of** the first hash in the locator list that matches a block hash identifier held by the responder.  If no hashes match, there will be no INV messages sent.

*Use an empty locator to get an `inv` for block 1, and `getheaders` that block to discover the genesis block hash in the prevBlock field*

### Stop At Hash

The sender will stop sending inventory messages if it encounters this hash.  If the hash is never encountered, the sender will stop after 500 inventory messages or when it hits the blockchain tip.

## Server Implementations 

[Bitcoin Unlimited](https://github.com/BitcoinUnlimited/BitcoinUnlimited/blob/bucash1.7.0.0/src/net_processing.cpp#L1077)

## Client Implementations
