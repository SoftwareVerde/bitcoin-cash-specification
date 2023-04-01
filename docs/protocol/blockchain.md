# Blockchain

## What is a Blockchain

The Bitcoin Cash blockchain is a linear collection of [blocks](/protocol/blockchain/block).
The "state" of the blockchain is calculated by sequentially executing each set of changes (in the form of [transactions](/protocol/blockchain/transaction)) included in each block.

When a block is created it includes the [hash](/protocol/blockchain/hash) of the previous block; this cryptographically ensures the block's parent block cannot be changed without completely rebuilding the new block.
This chaining structure is similar to [git](//git-scm.com) commits&mdash;where a block is analogous to a commit (a set of file changes), and each commit's parent is tied directly to its parent, forming a chain.
Unlike git, in order to create a commit (i.e. a block) a certain amount of work must be performed.
This [proof of work](/protocol/blockchain/proof-of-work) prevents blocks from being created instantly, and is the mechanic that prevents old history from being rewritten, since modifying a block would change its hash and disconnect it from its previous children.
Therefore, changing a block requires that each of the child blocks be recreated as well.
With this property, changing old blocks becomes nearly impossible as long as the work to create a block is sufficiently time-intensive.

## Block Height

Blocks are applied sequentially, and therefore for a given chain, a block can be identified by its distance from the genesis block.
This distance is commonly referred to as `block height`.
There may be multiple blocks at the same block height if two blocks are built that share a previous block's hash.
Multiple blocks with the same block height are often referred to as "sibling" blocks, or "contentious" blocks.
Sibling blocks can happen if a block is created with sufficient work before the mining node has been made aware of the new (sibling) block.
Sibling blocks are incompatible with one another, and eventually one will become orphaned.
The [genesis block](/protocol/blockchain#genesis-block) is the first block in a chain, and has a block height of `0` (as its distance to the genesis block is zero).

As of [BIP-34](/protocol/forks/bip-0034), the `block height` is included within the [coinbase transaction](/protocol/blockchain/block#coinbase-transaction).

## Work

The longest valid chain with the most [proof of work](/protocol/blockchain/proof-of-work) is generally considered to be the main chain.
Work can be quickly verified by evaluating the block's [difficulty](/protocol/blockchain/proof-of-work/difficulty) and validated by checking the block's hash.
[Chainwork](/protocol/blockchain/proof-of-work#chainwork) is the summation of all work done on each block up to a point on the blockchain.
As of [HF-20171113](/protocol/forks/hf-20171113), chainwork is used to calculate new block's [difficulty adjustment](/protocol/blockchain/proof-of-work/difficulty-adjustment-algorithm) as of block height 504032.

## Blockchain Reorganization

When two valid blocks share the same block height, they are considered contentious blocks.
Contentious blocks can happen organically due to the random nature of mining&mdash;the likeliness being proportional to the block propagation speed and the time between blocks.
Slow-propagating blocks require a longer block interval in order to prevent contentious blocks.

When two blocks become contentious, the first-seen block is usually considered the valid block on the main chain; however, different nodes across the network may have seen different blocks first.
Consensus is formed when a second block is mined on a contentious block.
This second block may also be contentious, although a rare circumstance.
In this case, the process repeats and the race continues until consensus is reached.


```diagramLabel

1.  Blocks 2a and 2b are mined before the either have fully propogated throughout the network.

2.  Some nodes follow Block 2a, others follow Block 2b, depending on which block they received first.

3.  Block 3 is mined on top of Block 2b.  Nodes originally following Block 2a abandon Block 2A, and begin following Block 2b/3.

```

```mermaid
graph LR

0[Block 0] --- 1[Block 1]
1 --- 2b[Block 2b]
1 -.- 2a[Block 2a]
2b --- 3[Block 3]

style 2a stroke-width: 3px, stroke-dasharray: 5
```

Switching from one chain to another chain is often called a "reorg"&mdash;short for "blockchain reorganization".
When a reorg occurs, transactions that were previously valid may become invalid if a transaction on the other chain spent the same [transaction output](/protocol/blockchain/transaction#transaction-output) as the original transaction.
During a reorg, transactions that were dependent upon a transaction that was not included in the other chain will transitively become invalid as well.

```mermaid
graph LR

subgraph Block 0
    tx0(...)
end
subgraph Block 1
    tx0 --- tx1(Tx 1)
end
subgraph  Block 2b
    tx1 --- tx2b(Tx 2b)
end
subgraph  Block 3
    tx2b --- tx3(Tx 3)
end
subgraph  Block 2a
    tx1 -.- tx2a(Tx 2a)
end
tx2a -.- tx4(Tx 4)

style tx4 stroke-width: 3px, stroke-dasharray: 5
style tx2a stroke-width: 3px, stroke-dasharray: 5
```

When a reorg is processed, transactions that were originally accepted from the old chain are migrated to the new chain's [memory pool](/protocol/blockchain/memory-pool) if they are still valid.

## Genesis Block

The genesis block is the first block created within the blockchain.
The genesis block's [hash](/protocol/blockchain/hash) is hard-coded into software.
The properties that compose of the genesis block are:

### Block Header

| Property | Value |
| -- | -- |
| Hash | `000000000019D6689C085AE165831E934FF763AE46A2A6C172B3F1B60A8CE26F` | 
| Previous Block Hash | `0000000000000000000000000000000000000000000000000000000000000000` |
| Timestamp | `1231006505` |
| Hash Target | `1D00FFFF` |
| Nonce | `2083236893` |
| Merkle Root | `4A5E1E4BAAB89F3A32518A88C31BC87F618F76673E2CC77AB2127B7AFDEDA33B` |

The genesis block's merkle tree consists of a single coinbase transaction.

### Coinbase Transaction

| Property | Value |
| -- | -- |
| Version | `1` |
| Lock Time | `0` |
| Transaction Input Sequence Number | `4294967295` |
| Transaction Output Amount | `5000000000` |

#### Unlocking Script

The unlocking script performs three pushes:
1. The block's encoded target hash.
2. An extra nonce (`4`).
3. The ASCII encoded string: `The Times 03/Jan/2009 Chancellor on brink of second bailout for banks`

Encoded as [script](/protocol/blockchain/script):

1.    `0x04 0xFFFF001D`
2.    `0x01 0x04`
3.    `0x45`<br/>`54686520 54696D65 73203033 2F4A616E`<br/>`2F323030 39204368 616E6365 6C6C6F72`<br/>`206F6E20 6272696E 6B206F66 20736563`<br/>`6F6E6420 6261696C 6F757420 666F7220`<br/>`62616E6B 73`

#### Locking Script

The locking script is a [pay to public key](/protocol/blockchain/address#pay-to-public-key) script for public key:

    04678AFD B0FE5548 271967F1 A67130B7
    105CD6A8 28E03909 A67962E0 EA1F61DE
    B649F6BC 3F4CEF38 C4F35504 E51EC112
    DE5C384D F7BA0B8D 578A4C70 2B6BF11D
    5F
    
    
### Serialized

The serialized genesis block has the hex encoded value of:

    01000000 00000000 00000000 00000000
    00000000 00000000 00000000 00000000
    00000000 3BA3EDFD 7A7B12B2 7AC72C3E
    67768F61 7FC81BC3 888A5132 3A9FB8AA
    4B1E5E4A 29AB5F49 FFFF001D 1DAC2B7C
    01010000 00010000 00000000 00000000
    00000000 00000000 00000000 00000000
    00000000 0000FFFF FFFF4D04 FFFF001D
    01044554 68652054 696D6573 2030332F
    4A616E2F 32303039 20436861 6E63656C
    6C6F7220 6F6E2062 72696E6B 206F6620
    7365636F 6E642062 61696C6F 75742066
    6F722062 616E6B73 FFFFFFFF 0100F205
    2A010000 00434104 678AFDB0 FE554827
    1967F1A6 7130B710 5CD6A828 E03909A6
    7962E0EA 1F61DEB6 49F6BC3F 4CEF38C4
    F35504E5 1EC112DE 5C384DF7 BA0B8D57
    8A4C702B 6BF11D5F AC000000 00

