# SPV

Simplified Payment Verification (SPV) is an alternative method for Bitcoin Cash clients to verify [transactions](/protocol/blockchain/transaction) without access to the entire [blockchain](/protocol/blockchain).
Clients that implement SPV typically do not store, validate, or broadcast most of the [blocks](/protocol/blockchain/block) on the chain, and thus, significantly reduce the resources needed for operation.
In contrast, nodes that store the full blockchain are often referred to as full nodes.

## Theory

The validity of transactions can not only be verified through checking the transactions against the public ledger, but can also be demonstrated through the facts that they have been accepted by the Bitcoin Cash network and admitted into the blockchain.
SPV relies on the latter method mentioned and verifies transactions by querying other network nodes for de facto proof that the blocks containing the transactions are valid.
The clients can keep their own copy of the [block header](/protocol/blockchain/block/block-header) chain and verify that the blocks referred are included in the blockchain.
The clients can further increase their confidence for the validity of the said transactions, as the confirmations go up due to the increased difficulty to forge the additional blocks and the decreased likelihood of a [blockchain reorganization](blockchain#blockchain-reorganization).

## Design

The support for SPV was proposed in [BIP-37](/protocol/forks/bip-0037).
Clients that wish to operate in SPV mode should utilize the [`filterload`](/protocol/network/messages/filterload) and [`filteradd`](/protocol/network/messages/filteradd) messages to request the remote peers to install and add content to the bloom filter on its connection with the client.
A Bloom filter is a probabilistic data structure which allows for testing set membership - they can have false positives but not false negatives.
Upon receipt of these messages, the remote peers are expected to only announce transactions selected by the filter, with the matching algorithm proposed in [BIP-37](/protocol/forks/bip-0037).
Nodes that accept a filterload message are expected to only send [inventory messages](/protocol/network/messages/inv) containing transactions that match the client's bloomfilter, or blocks that contain transactions that match the client's Bloom filter.
When blocks are requested by the client, they are sent not as [`block`](/protocol/network/messages/block) messages, but as [`merkle block`](/protocol/network/messages/merkleblock) messages, which contain the partial [merkle trees](/protocol/blockchain/block/merkle-tree) of the blocks as the proof of the inclusion for the transactions announced.
The transactions can be transmitted to the clients normally, via [`tx`](/protocol/network/messages/tx) messages.
The clients can utilize the [`filterclear`](/protocol/network/messages/filterclear) message to clear the Bloom filter on the connection, to revert the connection to its typical state.

## Advantages and Disadvantages

SPV allows the clients to only receive, store, and validate parts of the blockchain without hampering their ability to verify the transactions they care about, and thus, significantly reduce the storage space, computational power and network traffic needed for operation.
Such characteristics make them ideal for environments with meager performance, or on metered networks, such as mobile wallets.

However, SPV method typically requires more confirmation times to build up confidence for transactions, and in the event of an attack, such clients will not be able to detect the fabricated transactions as long as the attacker can overpower the network.
In addition, SPV also has known flaws that weaken the security and privacy of clients and allow denial-of-service attack vectors on full nodes that support SPV.
