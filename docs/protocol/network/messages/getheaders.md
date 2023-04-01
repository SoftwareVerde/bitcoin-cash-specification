<div class="cwikmeta">
{
"title":"GETHEADERS",
"related":["/protocol"]
} </div>

# Request: Get Headers ("getheaders")

Request a sequence of block hash identifiers

## Message Format

| Field | Length | Format | Description |
|--|--|--|--|
| locator | variable | [vector](/protocol/p2p/vector) of 32 byte block [hash identifiers](/glossary/hash__identifier) | identifies the location of the desired headers |
| stop at hash | 32 bytes | bytes | stop providing headers at this hash

### Locator

The locator is an array of block hash identifiers whose purpose is to communicate a position in a blockchain that may be forked from the blockchain that the receiver sees as having the most work.  It does so by providing a series of block hash identifiers ranging from the desired height to the genesis block.  The locator solves both major currency forks and minor forks caused by near-simultaneous block discovery.

The first hash in the locator is the parent of the desired identifiers.  Subsequent elements are ancestors of previous elements, chosen by the client.  A common strategy is to provide M direct ancestors and then make the M+Nth element the 2^Nth ancestor, finishing with the genesis block.  This results in an amount of data that is approximately the log of the length of the chain ([C++](https://github.com/BitcoinUnlimited/BitcoinUnlimited/blob/eb264e627e231f7219e60eef41b4e37cc52d6d9d/src/chain.cpp#L32)).

The response will begin at **the child of** the first hash in the locator list that matches a block hash identifier held by the responder.  If no hashes match, the response will begin at block height 1 (child of the genesis block). 

If the locator has no entries, the locator is ignored (see Stop At Hash).

*Use a valid locator whose first element is your chain tip and a zero "Stop At Hash" to request up to 2000 headers that extend your chain tip.*

### Stop At Hash

If a non-empty locator is provided, when constructing a response message, the sender will stop at the provided hash.  If the hash is never encountered, the sender will stop after 2000 block hash identifiers are included in the reply. 

If the locator is empty, the response includes only the header identified by this field (note it  **includes** this hash, which differs from the behavior of the locator).  In this case, if this hash is not found in the blockchain, the request is silently ignored.

*Use an empty locator and a valid block hash identifier to request the header of a specific block.*

## Server Implementations

[Bitcoin Unlimited](https://github.com/BitcoinUnlimited/BitcoinUnlimited/blob/bucash1.7.0.0/src/net_processing.cpp#L1131)

## Client Implementations
