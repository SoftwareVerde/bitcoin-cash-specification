# Difficulty Adjustment Algorithm

In order to correct for changes in the Bitcoin Cash network's total hashing power (i.e. as hardware improves or nodes are added to or removed from the network), the amount of work required to mine a block must change in tandem.
Bitcoin Cash solves this by adjusting the [target](/protocol/blockchain/proof-of-work#target) according to an algorithm that looks at recent block timestamps, infers the hashing power that led to those timestamps, and attempts to change the [difficulty](/protocol/blockchain/proof-of-work#difficulty) of mining future blocks accordingly.
The calculation used is referred to as the Difficulty Adjustment Algorithm, or DAA, and has changed a number of times.
In order to validate the blockchain, however, the difficulty must be verified using the DAA that was in use when that block was mined.
Consequently, the historical DAAs remain relevant to node implementation that wish to validate historical headers.

The algorithms used, from newest to oldest, are:

 - [ASERT](#asert)
 - [CW-144](#cw-144)
 - [Emergency DAA](#emergency-daa)
 - [Legacy DAA](#legacy-daa)

## ASERT

Absolutely Scheduled Exponentially Rising Targets (ASERT), more specifically [aserti3-2d](/protocol/forks/2020-11-15-asert), was implemented as a part of [HF-20201115](/protocol/forks/hf-20201115).
It uses an [exponential moving average](https://en.wikipedia.org/wiki/Moving_average#Exponential_moving_average) approach that should theoretically always target a correction toward a 10 minute average block time.
ASERT bases it's calculations on the following components:

 1. The **fork block**: The first block mined with the ASERT DAA
 2. The **anchor block**: The parent of the fork block
 3. The current head block

Though this is not used directly in practice, the exponential form of the calculation of the target for the next block is:

```
exponent = (time_delta - ideal_block_time * (height_delta + 1)) / halflife
next_target = anchor_target * 2**(exponent)
```

where:

- `anchor_target` is the unsigned 256 bit integer equivalent of the `nBits` value in
  the header of the anchor block.
- `time_delta` is the difference, in signed integer seconds, between the
  timestamp in the header of the current block and the timestamp in the
  parent of the anchor block.
- `ideal_block_time` is a constant: 600 seconds, the targeted
  average time between blocks.
- `height_delta` is the difference in block height between the current
  block and the anchor block.
- `halflife` is a constant parameter sometimes referred to as
  'tau', with a value of 172800 (seconds) on mainnet.
- `next_target` is the integer value of the target computed for the block
  after the current block.

In order to avoid subtle platform-dependent floating point issues, however, ASERT is instead calculated using fixed-point integer arithmetic with a cubic polynomial approximation of the exponential.
See [ASERT:target computeration](/protocol/forks/2020-11-15-asert#target-computation) for the Python reference implementation and additional details on where new implementations of the algorithm must be cautious to ensure full compatibility.

## CW-144

CW-144 attempts to ensure that the difficulty of new blocks is always closely tied to the amount of work done on recent blocks.
The name referes to the fact that it evaluates the difference in [chainwork](/protocol/blockchain/proof-of-work#chainwork) (CW) across the most recent 144 blocks.
Put into place as a part of [HF-20171113](/protocol/forks/hf-20171113), it performs the following calculation to determine the difficulty of a block, <code>B<sub>n+1</sub></code>, with block height `n+1`:

 - Select <code>B<sub>new</sub></code>: The block with the median timestamp of the blocks <code>B<sub>n</sub></code>, <code>B<sub>n-1</sub></code>, and <code>B<sub>n-2</sub></code>
 - Select <code>B<sub>old</sub></code>: The block with the median timestamp of the blocks <code>B<sub>n-144</sub></code>, <code>B<sub>n-145</sub></code>, and <code>B<sub>n-146</sub></code>.
 - Calculate `t`, the difference between the timestamps of <code>B<sub>new</sub></code> and <code>B<sub>old</sub></code>.  If this difference is less than `72 * 600`, use `72 * 600`, if it is above `288 * 600`, use `288 * 600`.
 - Calculate `W`, the difference in chainwork between <code>B<sub>new</sub></code> and <code>B<sub>old</sub></code>.
 - Calculate `PW`, the projected work for the next block, as `(W * 600) / t`.
 - Calculate `T`, the target difficulty, as <code>(2<sup>256</sup> - PW) / PW</code>.  In 256-bit two's-complement arithmetic, this is equivalent to `(-PW) / PW`.
 - If `T` is greater than the maximum target of `0x00000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF`, use the maximum target.  Otherwise, use `T`.

In other words, for any given block the projected work is be equal to the difference in chainwork multiplied by an adjustment.  The adjustment is 600 seconds (the goal timeframe for a block to be mined) divided by the difference in timestamps between the median block (by timestamp) of its prior three immediate ancestors and its 144th, 145th, and 146th ancestors (bounded by `72 * 600` and `288 * 600`).  The projected work is then converted into the target by subtracting it from 2<sup>256</sup> and then dividing the result by the projected work.  Then minimum of that calculated value and the maximum target is then used as the target for that block.

## Emergency DAA

As a part of [BCH-UAHF](/protocol/forks/bch-uahf), due to the anticipated decrease in hashing power, the following adjustment to the legacy difficulty adjustment algorithm above was put into place:

>In case the MTP of the tip of the chain is 12h or more after the MTP 6 block before the tip, the proof of work target is increased by a quarter, or 25%, which corresponds to a difficulty reduction of 20% .
>
> RATIONALE: The hashrate supporting the chain is dependent on market price and hard to predict. In order to make sure the chain remains viable no matter what difficulty needs to adjust down in case of abrupt hashrate drop.

That is, if the block height is not divisible by 2016, the target may still be adjusted if the current MTP is more than 12 hours after the MTP from 6 blocks prior.  In this case, the target is multiplied by 1.25.

This algorithm was superseded by the current difficulty adjustment algorithm as a part of HF-20171113.

## Legacy DAA

Prior to [BCH-UAHF](/protocol/forks/bch-uahf), the original Bitcoin difficulty adjustment algorithm was used.
To determine the difficulty of a block, <code>B<sub>n+1</sub></code>, with block height `n+1`:

 - If the `n` (or the current block height) is **not** divisible by 2016, use the target of the last block, B<sub>n</sub>.  Otherwise, continue.
 - Get the 2015th ancestor of the last block, B<sub>n-2015</sub> (this was originally intended to be the 2016th ancestor but due to a bug in the original implementation, the 2015th was used instead).
 - Get the last block, B<sub>n</sub>.
 - Calculate `t`, the difference between the timestamp of B<sub>n</sub> and B<sub>n-2015</sub>.
 - Calculate `c`, the correction factor by dividing `t` by the number of seconds in two weeks (`2 * 7 * 24 * 60 * 60 = 1,209,600`).  Note this is the expected time for 2016 blocks at a rate of one block every ten minutes (`2016 * 10 * 60 = 1,209,600`). If the result is less than `0.25`, use `0.25`.  If it is greater than `4`, use `4`.
 - Calculate the new target, `T`, by multiplying the target of B<sub>n</sub> by `c`.
 - If `T` is greater than the maximum target of `0x00000000FFFF0000000000000000000000000000000000000000000000000000`, use the maximum target instead.  Otherwise, use `T`.

This boils down to a possible change in difficulty every 2016 blocks, where the new target (for the next 2016 blocks) is calculated by dividing the time taken for the last 2015 blocks by the time expectation for 2016 blocks (bounded by 0.25 and 4) and multiplying that ratio  by the existing target.
