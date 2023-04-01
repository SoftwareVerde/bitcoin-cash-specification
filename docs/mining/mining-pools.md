# Mining Pools

Mining pools coordinate the efforts of a (typically large) group of miners.
When a block is mined, the [block reward](/protocol/blockchain/block#coinbase-transaction) is distributed amongst the contributing members of the pool.
This cooperation converts the discrete nature of block rewards into a continuous income for miners, allowing for all members to receive rewards whenever anyone in the pool successfully mines a new block.

Miners generally connect to pools using the [Stratum protocol](/mining/stratum-protocol).
While mining, miners submit shares in addition to valid blocks, allowing the pool to statistically verify that the miner is actively performing work toward the provided jobs.
This mechanism also allows pools to distribute the block reward proportionally, based on the amount of work performed by each miner.
The amount and timing of reward distribution varies by pool.