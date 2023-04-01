# Transaction Ordering

Transactions in a Block are inherently ordered by virtue of their inclusion in the [Merkle Tree](/protocol/blockchain/block/merkle-tree).
Furthermore, the [Coinbase Transaction](/protocol/blockchain/block#coinbase-transaction) is required to be the first Transaction in the Block.
After that, the order of any remaining Transactions in the block is dependent on when that Block was mined.  For new blocks, the [Canonical Transaction Ordering](#canonical-transaction-ordering) rule is in effect.
For historic blocks, see [Topological Transaction Ordering](#legacy-transaction-ordering).

## Canonical Transaction Ordering

With canonical transaction ordering (CTOR), the transactions after the coinbase transaction are required to be sorted in lexicographical order by transaction hash. The transaction hash is interpreted as little endian during sort. CTOR was scheduled to activate at median-time-past time 1542300000 and activated at block height 556766 (inclusive) on mainnet. 
After activation, blocks that do not follow this constraint will be rejected by the network.

CTOR is also sometimes referred to as LTOR (lexicographical transaction ordering). 

See [HF20181115](/protocol/forks/HF20181115) for more information on this change.

## Topological Transaction Ordering

With topological transaction ordering, Transactions after the Coinbase Transaction were required to abide by the following constraint: if a transaction B spends outputs created by transaction A, transaction B must appear after transaction A in the block.
Otherwise, transactions could appear in any order.

Before CTOR activated (block height < 556766) this was the required transaction order. 
