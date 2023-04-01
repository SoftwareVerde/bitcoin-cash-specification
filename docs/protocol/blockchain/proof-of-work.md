# Proof of Work

Bitcoin Cash uses a [hashcash](https://en.wikipedia.org/wiki/Hashcash)-like algorithm as a primary metric for validating new blocks.
The [block header](/protocol/blockchain/block/block-header) is hashed, its nonce is changed, and it is hashed again, until the resulting hash is below a certain [target](#target).
For more information on how mining is performed in practice, see [Mining](/protocol/blockchain/proof-of-work/mining).

Because SHA-256 is used to hash block headers, and it is not known how to find a input matching a certain output format, the proof-of-work system employed by Bitcoin Cash distributes the following quasi-randomly to the individual that successfully creates a block that meets the proof-of-work requirements:

 1. The responsibility of determining which transactions will appear in the block.
 2. The receipt of the block reward for the block.
 3. The receipt of the fees for the block.

This is only quasi-random because the likelihood of building a block with an appropriate hash is directly proportional to the computational power (often referred to as hashing power), available to each individual mining blocks.

## Target

As the network's hashing power changes, the proof-of-work algorithm adjusts to compensate.
With a stated goal of averaging 10 minutes per block mined, the work required to successfully mine a block is periodically adjusted to match the actual rate at which blocks were mined over a given period of time.
At any given point, the next block to be mined must hash to a value that, when interpreted as an integer, must be below a value that is deterministically calculated using the difficulties and timestamps of prior blocks.
This is value is referred to as the target.
For more details on how the target is calculated, see [Difficulty Adjustment Algorithm](/protocol/blockchain/proof-of-work/difficulty-adjustment-algorithm).

## Difficulty

Though the term difficulty is often used colloquially to refer generally to the changes to the target as blocks are mined, it can also refer specifically to the integer value of one target divided by another.
Generally, the numerator is a base target, e.g. the [genesis block](/protocol/blockchain#genesis-block) target, while the denominator is the target of the block whose "difficulty" is to be calculated.
This results in two benefits relative to using targets directly:

 - **More Intuitive:** Higher numbers mean the block required more hashing power to mine, while lower number mean less hashing power was required.  Increased difficulty is easier to understand than decreased target, even though these means the same thing.
 - **More Manageable:** The difficulty calculation produces much more human-readable numbers than trying to interpret targets as an integer directory.

## Chainwork

Chainwork is a representation of the work performed through a block's entire history.
It is the [expected](https://en.wikipedia.org/wiki/Expected_value) number of hashes required to re-solve every block in the chain.
It is calculated using the difficulties of each of the blocks in the chain.
The work for a single block is calculated as <code>2<sup>256</sup> / (target + 1)</code>, or equivalently in 256-bit two's-complement arithmetic, `(~target / (target + 1)) + 1`, where `~` is the bitwise NOT operation.
The chainwork for a block is the sum of its work with the work of all the blocks preceeding it.
As such, when a new block is mined, its chainwork is simply its work plus the chainwork of the block before it.

This algorithm implies that summing chainwork makes sense.
More formally, the expected number of hashes to solve one block candidate with work `W` is equal to the expected number of hashes to solve `N` block candidates with work `W/N`.
This, and that chainwork is the expected number of hashes, is proved [here](/protocol/blockchain/chainwork-proof).

## Extra Nonce

Ideally in such a proof-of-work system, the dynamic parameters of the data being hashed (i.e. the block header) would provide enough variability to guarantee any possible output of the hash function used.
However, SHA-256 outputs 32 bytes and the only part of the block header that can be changed rapidly are the nonce, which is only 4 bytes long, and the timestamp, which while also 4 bytes must remain close to the current time.
As a result, there was a need for additional data to be varied.

The only other parameter of the block header that a miner has any power over is the merkle root.
In order to change the merkle root, the transactions in the block would need to be changed.
But since the [coinbase transaction](/protocol/blockchain/block#coinbase-transaction) is already created by the miner of the block, and updating its hash would allow for efficient re-calculation of the merkle root, putting this "extra nonce" in the coinbase transaction was the logical conclusion.
Ultimately, the extra nonce is included as a part of the coinbase message, usually following the block height that is required to be first.
