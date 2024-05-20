# Block

A block is a collection of transactions that have been committed to the blockchain as a bundle.
The transactions do not necessarily have to be related to one another and, generally, are only associated by virtue of when they were submitted to the Bitcoin Cash network.

Every block contains one coinbase transaction, followed by zero or more additional transactions.
The coinbase transaction is created by the miner of the block and provides an opportunity for them to receive the block reward for successfully mining a block, along with any fees collected from the transactions in the block.
For more information, see [Mining](/protocol/mining).

## Block Headers

Block are identified by the SHA-256 hash of their header.
Since the block header contains the root of a [Merkle Tree](/protocol/blockchain/merkle-tree) of the transactions in the block, this means the hash is ultimately dependent on both the meta-information about the block as well as the full contents of all of its component transactions.

For more information see [Block Header](/protocol/blockchain/block/block-header).

## Coinbase Transaction

The coinbase transaction provides a mechanism for miners to:

 - Receive payment for mining.
 - Include a message, known as the "coinbase message," or simply "coinbase," within the block.

To accomplish this, the coinbase transaction is required to have a single input.
However, unlike other transactions, this input is not expected to provide the satoshis that appear in the outputs.
Instead, the satoshis that appear in the outputs of the coinbase transaction are collected from two places: the block reward and transactions fees.

The block reward is provided automatically to the block and represents a continually decreasing incentive for miners.
The block reward started at 5,000,000,000 satoshis (50 BCH) and decreases by half every 210,000 blocks.

Transaction fees are often required by the network for transactions to be relayed across the network.
Satoshis provided as inputs to a transaction, but not consumed by its outputs, are collected by the coinbase transaction as implicit inputs.

The coinbase message is provided in the inputs unlocking script.
The unlocking script is required to begin with a push of the block height which can then be followed why whatever data is desired.
The block height encoded as a variable-length, little-endian integer.
The [OP_DATA_X](/protocol/blockchain/script/op-codes/op-data-x) operation is used to push the necessary number of bytes to encode the length.
This requirement was added with version 2 blocks as a part of [BIP-34](/protocol/forks/bip-0034). 
As per [HF-20191115](/protocol/forks/hf-20191115), the block height included in the unlocking script should also be minimally encoded. 
This consensus is currently enforced by several node implementations, including Bitcoin Cash Node, Bitcoin Verde, and Flowee the Hub. 
Other node implementations including BCHD, and Bitcoin Unlimited, will if the block height is included in the coinbase transaction but would not check if the included block height is minimally encoded.  

Each coinbase transaction may only have one transaction input.

Each coinbase transaction's unlocking script must be less than or equal to 100 bytes.

## Block Size

The maximum block size for blocks is 32MB (32 * 1000 * 1000 bytes).
The maximum number of transactions within a block is a function of this limit divided by the minimum transaction size, of 100 bytes.
Other rules limit the number of transactions that may be within a block, including the number of signature operations ("sigops") within a block.
