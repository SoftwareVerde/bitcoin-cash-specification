# Memory Pool

The Bitcoin Cash memory pool, or mempool, is a staging area for valid Bitcoin Cash [transactions](/protocol/blockchain/transaction) waiting to be added to the [blockchain](/protocol/blockchain).
[Valid transactions](/protocol/blockchain/transaction-validation) received from the network are usually cached in the mempool and are removed once they are mined into a [block](/protocol/blockchain/block).
Bitcoin Cash nodes typically employ mempools to increase their responsiveness, enabling them to accept and validate transactions anytime even though new blocks are only mined once per 10 minutes on average.
Mining nodes are also incentivized to do so in order to collect larger amounts of transaction fees from groups of transactions for every block mined.

Transactions in the mempool are usually treated as if they were in an imaginary block after the current highest block in the blockchain to apply relevant policies, such as double-spending prevention and maximum block size.
Transactions in the mempool may also be tracked with respect to chaining.
Transaction chaining happens when one transaction spends the output of another transaction in the same block.
In such cases, the transactions that provide the said output are typically referred to as parent transactions, and the ones spend the said output as child transactions.
The tracking of transaction chaining is vital for nodes to remove any dependent transactions in the mempool in the event that their parent transactions are removed and thus invalidate such transactions.
Nodes may also limit the maximum depth of transaction chaining due to computational complexity concerns.
However, more recent development on Bitcoin Cash saw such limits increased or removed due to functionality concerns.

Although this rarely occurs, mempools may reach their maximum capacity set by the node and may reject incoming transactions from the network or remove existing transactions from the mempool under such occasions.
The policies regarding such scenarios are at the discretion of each node.
Apart from the capacity reasons, transactions that once were considered valid may still be rejected from adding to the mempool or removed from the mempool for other reasons.

## Rejection of transactions to the mempool

Valid transactions may be rejected by the node to enter the mempool for several typical reasons.

1. Transactions may be rejected if they fail to meet the minimum transaction fee set by the node.
This usually happens if the mempool is approaching its capacity or if the transactions are considered [dust transactions](/protocol/blockchain/transaction-validation/network-level-validation-rules#dust).
2. Transactions that double spend inputs of another transaction already in the mempool will be rejected.
3. [Non-standard](/protocol/blockchain/transaction-validation/network-level-validation-rules#standard-transactions) transactions are often rejected.

## Removal of transactions from the mempool

Under few rare circumstances, transactions that are already admitted to the mempool may be removed without being mined into the blockchain.
The reasons for such removal may include but not limited to:

1. Nodes may remove the transactions that are no longer valid after a blockchain reorg, such as transactions that double spend inputs of existing transactions in the blockchain or transactions that spend outputs that are now time-locked due to reduced block height or earlier median time-past (MTP) after the blockchain reorg.
2. Transactions may be removed when new blocks are received, such as transactions included in the received blocks or transactions that double spend inputs of transactions in the new blocks.
3. Nodes may remove transactions due to performance or capacity constraints.

Typically, transactions that provide low fees may be removed when the mempool is approaching its capacity or after prolonged periods in the mempool without being mined.
