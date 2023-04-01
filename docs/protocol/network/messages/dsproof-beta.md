# Announcement: Double Spend Proof ("dsproof-beta")

This message is meant to inform participants of attempts of double spending an unconfirmed transaction by providing cryptographic provable evidence that one UTXO entry was spent twice by the owner(s) of the funds.

## Summary

A double spend attack can be used, for instance, to redirect payments sent to a specific merchant to a different target and thus defraud the merchant.
The basic concept of a double spend is that (at least) one unspent output is spent twice in different transactions which forces miners to pick one of them to mine.

At its most basic level, this can be detected by finding two signed inputs both spending the same output.
In the case of pay-to-public-key-hash (P2PKH) this means two signatures from the same public key.

Cryptographic signatures in Bitcoin Cash follow the "fork-id" algorithm described [here](/protocol/forks/replay-protected-sighash).
Since a hash of the transaction is signed, the protocol sends only the intermediate components used to build the preimage for the hash, while still allowing receivers to validate both signatures of the same public key, and therefore proving that a double spend has taken place.

## Network specification

A node that finds itself in possession of a correct double-spend-proof
shall notify its peers using the [inventory](/protocol/network/messages/inv) message, using a "type" field with the value **`0x94A0`**.
This inventory type value will be changed to another number once double-spend proofs move out of beta and is finalized.

The hash-ID for the double-spend-proof is a double sha256 over the entire serialized content of the proof, as defined next.

In response to an inventory message, any peer can issue a [getdata](/protocol/network/messages/getdata) message which will cause a reply with the following message.
This type of message is **`dsproof-beta`** but will be changed to another identifier once double-spend proofs move out of beta and is finalized.

| Field | Length | Format | Description |
| -----------|:-----------:| ----------:|---------:|
| previous [transaction output](/protocol/blockchain/transaction#transaction-output)'s transaction hash | 32 | sha256<sup>[(LE)](/protocol/misc/endian/little)</sup> | The **transaction hash** of the output being spent |
| previous [transaction output](/protocol/blockchain/transaction#transaction-output)'s index | 4 | unsigned integer<sup>[(LE)](/protocol/misc/endian/little)</sup> | The **index** of the transaction output being spent |
| first spender | variable | spender<sup>[(BE)](/protocol/misc/endian/big)</sup> | The preimage data structure needed to validate a transaction's signature. |
| second spender | variable | spender<sup>[(BE)](/protocol/misc/endian/big)</sup> | The preimage data structure needed to validate a transaction's signature. |

A double-spend-proof describes two inputs, both spending the same output.
As such the previous transaction output's hash and previous transaction output's index point to the output and the spenders each describe inputs.

### Spender Format

The `spender` format is as follows.
Each field in the (below) table's `description` column loosely corresponds to the name of the preimage component used when generating transaction signatures per the [transaction signing algorithm](/protocol/blockchain/transaction/transaction-signing).

| Field | Length | Format | [Signature Preimage](/protocol/blockchain/transaction/transaction-signing#preimage-format) Component | Description |
| -----------|:-----------:| ----------:|---------:|---------:|
| tx version | 4 | unsigned integer<sup>[(LE)](/protocol/misc/endian/little)</sup> | #1 | Copy of the transactions version field |
| sequence | 4 | unsigned integer<sup>[(LE)](/protocol/misc/endian/little)</sup> | #7 | Copy of the sequence field of the input |
| locktime | 4 | unsigned integer<sup>[(LE)](/protocol/misc/endian/little)</sup> | #9 | Copy of the transactions locktime field |
| hash prevoutputs | 32 | sha256 | #2 | Transaction hash of prevoutputs |
| hash sequence | 32 | sha256 | #3 | Transaction hash of sequences |
| hash outputs | 32 | sha256 | #8 | Transaction hash of outputs |
| push-data count | variable | [variable length integer](/protocol/formats/variable-length-integer) | | Number of push-data objects within in the push-data list |
| push-data | variable | bytes | #10 | List of push-data objects |

### Push Data Format

The `push data` format is as follows.
Each item is a value pushed by the [unlocking script](/protocol/blockchain/transaction/unlocking-script).

| Field | Length | Format | Description |
| -----------|:-----------:| ----------:|---------:|
| byte count | variable | [variable length integer](/protocol/formats/variable-length-integer) | The number of bytes in this push-data object |
| bytes | variable | bytes <sup>[(BE)](/protocol/misc/endian/big)</sup> | The resulting bytes pushed by an [unlocking script](/protocol/blockchain/transaction/unlocking-script)'s push [operation](/protocol/blockchain/script#operation-codes-opcodes) (ex. signature data). |

## Validation

It is required that nodes validate the proof before using it or forwarding it to other nodes.
Double spend proofs only apply to transactions within the [memory pool](/protocol/blockchain/memory-pool).
Validated double spend proofs should be advertised (via [inventory message](/protocol/network/messages/inv)) to all connected peers.
If a peer has a bloom filter set, nodes should only relay double spend proofs that the [bloom filter](/protocol/spv/bloom-filter).

Validation includes a short list of requirements;

1. The message is well-formed and contains all fields.
It is allowed for some hashes to be all-zeros.
2. The two `spenders` must be different.
3. The first &amp; double `spender`s are sorted via the following algorithm:

  3a. sort via the `hash-outputs` field of the `spender`.

  3b. if `hash-outputs` are equal, then compare on `hash-prevoutputs`.

  The sorting order is in numerically ascending order of the hash, interpreted as 256-bit [little endian](/protocol/misc/endian/little) integers.

4. The double spent output is still available in the UTXO database, implying no spending transaction has been mined.

5. The push data elements of the two signers are different.

6. No other valid proof is known.

Further validation can be done by validating the signature that
was copied from the inputs of both transactions against the (soon to be spent) previous transaction output.

To validate a spender of the proof, a node is required to have;

* The output being spent (mempool or UTXO)
* One of the transactions trying to spend the output.
* The double-spend-proof.

As the forkid [specification](/protocol/blockchain/transaction/transaction-signing#preimage-format) details, the digest algorithm hashes 10 items in order to receive a sha256 hash, which is then signed.

These 10 items are;

1.  nVersion of the transaction (4-byte little endian)
2.  hashPrevouts (32-byte hash)
3.  hashSequence (32-byte hash)
4.  outpoint (32-byte hash + 4-byte little endian)
5.  scriptCode of the input (serialized as scripts inside CTxOuts)
6.  value of the output spent by this input (8-byte little endian)
7.  nSequence of the input (4-byte little endian)
8.  hashOutputs (32-byte hash)
9.  nLocktime of the transaction (4-byte little endian)
10. sighash type of the signature (4-byte little endian)

The double spend message includes items: 1, 2, 3, 4, 7, 8, 9 and 10.

Items 5 &amp; 6 can be obtained from the output being spent.

The transaction that first spent the output within the node's [memory pool](/protocol/blockchain/memory-pool), can be used to get the public key required to validate that the signature within the `push-data` field of the double spend proof is correct.

When all rules are followed, the proof is valid.

## Limitation and risks

Not all types and all combinations of transactions are supported.
Wallets and point-of-sale applications are suggested to give a rating of how secure an unconfirmed transaction is based on various factors.

Transactions that spend all, confirmed, P2PKH outputs with all inputs signed `SIGHASH_ALL` without `ANYONECANPAY`, are double-spend-proof's "protected transactions".

## Node-Specific Behavior

### Bitcoin Verde

Bitcoin Verde supports an extended form of the `dsproof-beta` message.
For P2PKH outputs, the format is as described above for compatibility with other nodes.
For all other script types, the following changes are made to the existing data:

1. `hash prevoutputs` is always the non-zero version of hash (e.g. for `SIGHASH_ALL`, **not** `ANYONECANPAY` hash types).
2. `hash sequence` is always the non-zero version of the hash (e.g. for `SIGHASH_ALL`, **not** `ANYONECANPAY` hash types).
3. `hash outputs` is always all zero (0x00) bytes.
4. `push data` is defined to be the values push by every (push) operation in the unlocking scripts, except for P2SH, where the last value (the redeem script) is left off.

The following extra data is also appended after the second spender:

| Field | Length | Format | Description |
| -----------|:-----------:| ----------|---------|
| hash type count | 1 byte | [variable length integer](/protocol/formats/variable-length-integer) | The number of hashes to follow (always 2 with current signature rules). |
| hash type indicator 0 | 1 byte | byte | The hash type of the following hash (always 0x01 for `SIGHASH_ALL`). |
| hash outputs 0 | 32 bytes | sha256 | The hash outputs, as used in the signature preimage for a `SIGHASH_ALL` signature. |
| hash type indicator 1 | 1 byte | byte | The hash type of the following hash (always 0x03 for `SIGHASH_SINGLE`). |
| hash outputs 1 | 32 bytes | sha256 | The hash outputs, as used in the signature preimage for a `SIGHASH_SINGLE` signature. |

This format corresponds with Bitcoin Verde's proposal for an alternate double spend proof message that supports all script types.
