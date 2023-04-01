# Multisignature

Multisignature (often called "multisig") refers to requiring multiple keys to spend funds in a Bitcoin Cash transaction, rather than a single signature from one key. It has a number of applications and allows users to divide up responsibility for possession of coins.

Multisignature scripts set a condition where N public keys are recorded in the script and at least M of those must provide signatures to unlock the funds. This is also known as *M-of-N multisignature scheme*, where N is the total number of keys and M is the threshold of signatures required for validation. The signatures used can either be ECDSA signatures or Schnorr signatures.

## Public Multisignature: OP_CHECKMULTISIG(VERIFY)

Multisig schemes can be built with the opcodes `OP_CHECKMULTISIG` and `OP_CHECKMULTISIGVERIFY`, two opcodes of the Bitcoin Cash [scripting language](/protocol/blockchain/script). `OP_CHECKMULTISIGVERIFY` has the same implementation as `OP_CHECKMULTISIG`, except OP_VERIFY is executed afterward.

The opcode `OP_CHECKMULTISIG` can be included in all sorts of scripts. The minimal [locking script](/protocol/blockchain/transaction/locking-script.md) using `OP_CHECKMULTISIG` is:

```
M <pubkey1> ... <pubkeyN> N CHECKMULTISIG
```

This script creates a P2MS (raw multisig) output. It can also be used as a *redeem script* for a P2SH output.

The [unlocking script](/protocol/blockchain/transaction/unlocking-script) corresponding to the previous locking script is:

```
<dummy> <sig1> ... <sigM>
```

Upon script execution, this will act like:

```
<dummy> <sig1> ... <sigM> M <pubkey1> ... <pubkeyN> N CHECKMULTISIG
```

Due to a historical bug (the original implementation of `OP_CHECKMULTISIG` consumed `M+N+3` items on the stack instead of `M+N+2`), an extra unusued value called the `dummy` element was included in the script. This was usually done via `OP_0`. Since the [HF-2019115](/protocol/forks/hf-20191115) Bitcoin Cash upgrade, this element has been repurposed as a trigerring and execution mechanism. 

In particular, the value of the `dummy` element determines whether ECDSA or Schnorr signatures have to be used. If `dummy` is `0` (i.e., an empty byte array), then all signatures must be produced by ECDSA. If `dummy` is not `0`, then all signatures must be produced by the Schnorr algorithm and the `dummy` element is interpreted as a bitfield called `checkbits`.

Upon `OP_CHECKMULTISIG` execution, the ECDSA mode (`dummy = 0`) is:

* The first signature is checked against each public key until a match is found.
* Starting with the subsequent public key, the second signature is checked against each remaining public key until a match is found.
* The process is repeated until all signatures have been checked or not enough public keys remain to produce a successful result.
* All signatures need to match a public key, otherwise `false` is returned.

The Schnorr mode (`dummy = checkbits > 0`) operates similarly, but only checks signatures as requested, according to the `checkbits` field:

* If the least significant bit of `checkbits` is set, then the first signature is checked against the first public key. 
* If it is not but if the second least significant bit is set, then the first signature is checked against the second public key. 
* Once the first signature has been checked against a matching public key, `checkbits` is bit-shifted to the right (`checkbits := checkbits >> 1`).
* The process is repeated until all signatures have been checked or not enough public keys remain to produce a successful result.
* All signatures need to match a public key, otherwise `false` is returned.
* If the final `checkbits` value is non-zero, then `false` is returned. 

Because public keys are not checked again if they fail any signature comparison (in both cases), signatures must be placed in the unlocking script using the same order as their corresponding public keys were placed in the locking script (P2MS) or redeem script (P2SH).

Note that the `checkbits` element is encoded as a byte array of length `floor((N + 7)/8)` (the shortest byte array that can hold N bits) and must have exactly M bits set to ensure that all signatures are checked against public keys.

To know more about the Schnorr mode, see the [specification](https://github.com/bitcoincashorg/bitcoincash.org/blob/master/spec/2019-11-15-schnorrmultisig.md).

### Example

The most commonly used scheme is the 2-of-3 multisig scheme:

```
2 <pubkeyA> <pubkeyB> <pubkeyC> 3 CHECKMULTISIG
```

where 2 out of 3 participants (Alice, Bob and Carol) can sign a transaction from the shared account. 

Let's say Alice and Carol want to spend funds. If they want to use ECDSA, they have to sign the transaction with this algorithm and build the following script: 

```
0 <sigA> <sigC>
```

If they want to use Schnorr, they have to sign the transaction with this algorithm and build the following script: 

```
5 <sigA> <sigC>
```

The value of the `dummy` element is 5, whose binary representation is `0b101`. This ensures that Alice's signature (`sigA`) is checked against her public key (`pubkeyA`), that Carol's signature (`sigC`) is not checked against Bob's public key (`pubkeyB`) but against her public key (`pubkeyC`).

## Private Multisignature

N-of-N multisig schemes can also be implemented in P2PKH outputs, using the Schnorr aggregation property.
By combining the public keys of the cooperating parties, a combined public key can be created and used in a locking script.
When spending the output, the parties can jointly create a signature that will validate as a normal Schnorr signature for the combined public key in the locking script.
For more details, see [MuSig](https://eprint.iacr.org/2018/068).
