# Mining

The Bitcoin Cash mining process seeks to alter a proposed block until its hash, when interpreted an a number, is below a calculated [target](/protocol/blockchain/proof-of-work#target).
The [block header](/protocol/blockchain/block/block-header) is modified in two ways to achieve a new [hash](/protocol/blockchain/hash#sha-256).
Primarily, the `nonce` field is modified and can take any of its 2<sup>32</sup> possible values.
Then, as needed, the merkle root is changed by modifying the [coinbase message](/protocol/blockchain/block#coinbase-transaction) to include an [extra nonce](/protocol/blockchain/proof-of-work#extra-nonce).
In addition, the block timestamp is also updated occasionally to ensure that it remains reasonably current.

As the two nonces are rapidly and systematically changed, and the resulting block hash rapidly changes to seemingly random values each time, there is an increasing likelihood that one of the hashes will be below the specified target.
Once such a hash is found, the block is then broadcast to the network in hopes that no one else found a suitable block in the passing time.

## Types of Mining

Due to the various incentives for mining blocks, miners have employed a variety of techniques to maximize their profits.

 - **CPU Mining:** This was the initial approach, simply running the mining algorithm on a computer's processor, ideally multi-threaded so that for a CPU with N-cores (or [threads](https://en.wikipedia.org/wiki/Simultaneous_multithreading)), N candidate blocks could be hashed at a time, improving the throughput.
 - **[GPU](https://en.wikipedia.org/wiki/Graphics_processing_unit) Mining:** Since GPUs are particularly well-suited to parallel-processing, the use of GPUs allowed for significantly increased hashing power and, for a time, heavily increased the demand for high-end graphics cards.
 - **[ASIC](https://en.wikipedia.org/wiki/Application-specific_integrated_circuit) Mining:** Ultimately, purpose-built devices were created to perform mining as fast as physically possible.
These devices rapidly consume power and produce a considerable amount of heat and the people that run then often seek out the lowest available power prices and invest in cooling solutions that keep their mining devices (often just referred to as "miners") running at peek performance.