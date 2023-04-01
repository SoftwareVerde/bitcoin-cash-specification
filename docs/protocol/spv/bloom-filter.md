# Bloom Filter

A bloom filter is an imperfect but efficient set membership test.  The filter will never incorrectly report that member is NOT in the set.  However, it may report that a member is in a set when it is actually not.  See [wikipedia](https://en.wikipedia.org/wiki/Bloom_filter), or the [original paper](https://dl.acm.org/citation.cfm?id=362686.362692) for details.   

Bloom filters are used in the Bitcoin peer-to-peer protocol to filter the transactions and blocks that a client is sent from another node.  The client first "installs" a bloom filter that contains information about the objects it is interested in by sending a [filterload](/protocol/network/messages/filterload) message to a peer.   The peer will subsequently only provide objects that match the installed filter.

At a minimum, an [SPV](/protocol/spv) client must insert addresses and outpoints (identifiers of previous outputs, see [Outpoints](#outpoints)) into the bloom filter.  The addresses will cause every transaction that pays INTO the wallet to be reported, and the outpoints will cause every transaction that pays OUT OF the wallet to be reported.

Bitcoin Bloom filters have an additional feature.  Based on the setting of a flag byte, it is possible to direct the peer to automatically insert new data into the bloom filter based on transactions that match.  In particular, outpoints will be automatically inserted that correspond to the outputs of addresses that match the filter (see [Bloom Filter Flags](/protocol/network/messages/filterload#bloom-filter-flags)).  This facility is extremely important because if a receive and spend occur within the same transaction, the client does not have the opportunity to update the filter.  Bloom filters should therefore be sized with the expectation that new elements will be inserted.

However, due to the bloom filter's tendency to have false positives, these insertions mean that unwanted data will be inserted into the filter, creating even more false positives in a positive feedback loop.  Eventually the node will start sending a lot of unnecessary traffic to the client.  Therefore, it is essential for clients to periodically refresh the bloom filter (using [filterload](/protocol/network/messages/filterload)) to remove these unnecessary entries.

## Using Bloom Filters

At its most basic level, a bloom filter is a large bit-string.  Data to be added is hashed with a series of hash operations, whose outputs are interpreted as unsigned integers (modulo the number of bits in the bloom filter) are treated as indices for bits to be set.  To test if a value was previously added to the bloom filter, the same hash functions are run and those bit indices are checked.  If any of the checked bits are not set, then the value was definitely not previously added to the bloom filter.  If all of the bits are set, it is assumed the value was previously added, though the likelihood that it was depends heavily on the size of the bloom filter and the number of values that have been added.

Since the raw bloom filter data is transmitted between nodes as a part of the filterload message, it is important that all of the parameters are well-defined for a given bloom filter.  In Bitcoin, the hash function used is always [32-bit Murmur Hash version 3](https://en.wikipedia.org/wiki/MurmurHash).  The seed value used to initialize the Murmur hash is dependent on a tweak (or nonce), chosen at random by the creator of the bloom filter, and the number of hashes being performed (max of 50).  For each hash of the input data, the seed is calculated as: `hash_number * 0xFBA4C795 + tweak`.  So the seed for the first hash operation is `0 * 0xFBA4C795 + tweak`, the second is `1 * 0xFBA4C795 + tweak`, and so on, up to the number of hashes selected when the bloom filter was created.

In practice, the size of the bloom filter and the number of hash operations are calculated based on a target false-positive rate and an expected number of values to store.  Given a target false-positive probability, `P`, and number of items to add, `N`, the corresponding bloom filter size, `S`, is calculated as `(-1 / pow(log(2), 2) * N * log(P)) / 8`.  The number of hash operations is then calculated as `S * 8 / N * log(2)`.

For more detail, see [BIP-37](/protocol/forks/bip-0037).

## Outpoints

Outpoints are a form of serialized identifier for transaction outputs.  The format allows for the addition of specific outputs to a bloom filter, particularly for the purposes of matching a future transaction that spends that output.

### Format

| Field | Length | Format | Description |  
|--|--|--|--|
| transaction hash | 32 bytes | [transaction hash](/protocol/blockchain/hash)<sup>[(LE)](/protocol/misc/endian/little)</sup> | The hash of the transaction containing the referenced output. |
| output index | 4 bytes | unsigned integer<sup>[(LE)](/protocol/misc/endian/little)</sup> | This index of the output in the transaction. |