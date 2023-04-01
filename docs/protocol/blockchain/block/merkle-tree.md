# Merkle Tree

A [Merkle Tree](https://en.wikipedia.org/wiki/Merkle_tree) is a data structure designed to build a hash of many separate pieces of data and allowing efficient recalculation of the hash when items are added, removed, or changed.

In Bitcoin Cash, the transactions in a [Block](/protocol/blockchain/block) are built into a Merkle Tree.
The root of this tree, or *Merkle Root*, is a hash representing a compound, indirect hash of all of the items added to the Merkle Tree (i.e. transactions) and is included in the [Block Header](/protocol/blockchain/block/block-header), ensuring the block hash is dependent (indirectly) on all of the transactions that are included in the block.

Using a Merkle Tree to manage hashing the transactions in a Block enables efficient addition of newly submitted Transactions to a Block being mined.
Rather than re-hashing the entirety of the data of the Transactions to be included in the Block, the new Transaction can be hashed and then a small number of hashes can be recalculated, leading up to the Merkle Root.
For large Blocks this can heavily reduce the amount of data to be (re-)hashed.

Using Merkle Trees also allows for transferring only a subset of a Block while still providing confidence that the data provided in fact appeared in the Block in question.

For more information, see [Merkle Block](/protocol/network/messages/merkleblock). 