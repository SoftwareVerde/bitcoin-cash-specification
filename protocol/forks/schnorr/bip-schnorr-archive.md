# BIP-Schnorr (Archive)

    BIP: ?
    Title: Schnorr Signatures for secp256k1
    Author: Pieter Wuille <pieter.wuille@gmail.com>
    Status: Draft
    Type: Informational
    License: BSD-2-Clause
    Post-History: 2018-07-06: https://lists.linuxfoundation.org/pipermail/bitcoin-dev/2018-July/016203.html [bitcoin-dev] Schnorr signatures BIP

## Introduction

### Abstract

This document proposes a standard for 64-byte Schnorr signatures over the elliptic curve `secp256k1`.

### Copyright

This document is licensed under the 2-clause BSD license.

### Motivation

Bitcoin has traditionally used
[ECDSA](https://en.wikipedia.org/wiki/Elliptic_Curve_Digital_Signature_Algorithm) signatures over the [secp256k1 curve](http://www.secg.org/sec2-v2.pdf) for authenticating
transactions. These are [standardized](http://www.secg.org/sec1-v2.pdf), but have a number of downsides
compared to [Schnorr signatures](https://en.wikipedia.org/wiki/Schnorr_signature) over the same curve:

* **Security proof**: The security of Schnorr signatures is easily [provable](https://www.di.ens.fr/~pointche/Documents/Papers/2000_joc.pdf) in the random oracle model assuming the elliptic curve discrete logarithm problem (ECDLP) is hard. Such a proof does not exist for ECDSA.
* **Non-malleability**: ECDSA signatures are inherently malleable; a third party without access to the private key can alter an existing valid signature for a given public key and message into another signature that is valid for the same key and message. This issue is discussed in [BIP62](https://github.com/bitcoin/bips/blob/master/bip-0062.mediawiki) and [BIP66](https://github.com/bitcoin/bips/blob/master/bip-0066.mediawiki). On the other hand, Schnorr signatures are provably non-malleable<sup>[1](#footnotes)</sup>.
* **Linearity**: Schnorr signatures have the remarkable property that multiple parties can collaborate to produce a signature that is valid for the sum of their public keys. This is the building block for various higher-level constructions that improve efficiency and privacy, such as multisignatures and others (see Applications below).

For all these advantages, there are virtually no disadvantages, apart
from not being standardized. This document seeks to change that. As we
propose a new standard, a number of improvements not specific to Schnorr signatures can be
made:

* **Signature encoding**: Instead of [DER](https://en.wikipedia.org/wiki/X.690#DER_encoding)-encoding for signatures (which are variable size, and up to 72 bytes), we can use a simple fixed 64-byte format.
* **Batch verification**: The specific formulation of ECDSA signatures that is standardized cannot be verified more efficiently in batch compared to individually, unless additional witness data is added. Changing the signature scheme offers an opportunity to avoid this.

![Graph of batch signature verification speedup.](/protocol/forks/schnorr/bip-schnorr/speedup-batch.png)

This graph shows the ratio between the time it takes to verify `n` signatures individually and to verify a batch of `n` signatures. This ratio goes up logarithmically with the number of signatures, or in other words: the total time to verify `n` signatures grows with `O(n / log n)`.

By reusing the same curve as Bitcoin has used for ECDSA, private and public keys remain identical for Schnorr signatures, and we avoid introducing new assumptions about elliptic curve group security.

## Description

We first build up the algebraic formulation of the signature scheme by
going through the design choices. Afterwards, we specify the exact
encodings and operations.

### Design

**Schnorr signature variant** Elliptic Curve Schnorr signatures for message `m` and public key `P` generally involve a point `R`, integers `e` and `s` picked by the signer, and generator `G` which satisfy `e = H(R || m)` and `sG = R + eP`. Two formulations exist, depending on whether the signer reveals `e` or `R`:

1. Signatures are `(e,s)` that satisfy `e = H(sG - eP || m)`. This avoids minor complexity introduced by the encoding of the point `R` in the signature (see paragraphs "Encoding the sign of R" and "Implicit Y coordinate" further below in this subsection).
2. Signatures are `(R,s)` that satisfy `sG = R + H(R || m)P`. This supports batch verification, as there are no elliptic curve operations inside the hashes.

We choose the `R`-option to support batch verification.

**Key prefixing** When using the verification rule above directly, it is possible for a third party to convert a signature `(R,s)` for key `P` into a signature `(R,s + aH(R || m))` for key `P + aG` and the same message, for any integer `a`. This is not a concern for Bitcoin currently, as all signature hashes indirectly commit to the public keys. However, this may change with proposals such as SIGHASH_NOINPUT ([BIP 118](https://github.com/bitcoin/bips/blob/master/bip-0118.mediawiki)), or when the signature scheme is used for other purposes&mdash;especially in combination with schemes like [BIP32](https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki)'s unhardened derivation. To combat this, we choose `key prefixed`<sup>[2](#footnotes)</sup> Schnorr signatures; changing the equation to `sG = R + H(R || P || m)P`.

**Encoding the sign of R** As we chose the `R`-option above, we're required to encode the point `R` into the signature. Several possibilities exist:

1. Encoding the full X and Y coordinate of R, resulting in a 96-byte signature.
2. Encoding the full X coordinate, but only whether Y is even or odd (like compressed public keys). This would result in 65-byte signatures.
3. Encoding only the X coordinate, leaving us with 64-byte signature.

Using the first option would be slightly more efficient for verification (around 5%), but we prioritize compactness, and therefore choose option 3.

**Implicit Y coordinate** In order to support batch verification, the Y coordinate of `R` cannot be ambiguous (every valid X coordinate has two possible Y coordinates). We have a choice between several options for symmetry breaking:

1. Implicitly choosing the Y coordinate that is in the lower half.
2. Implicitly choosing the Y coordinate that is even<sup>[3](#footnotes)</sup>.
3. Implicitly choosing the Y coordinate that is a quadratic residue (has a square root modulo the field size)<sup>[4](#footnotes)</sup>.

The third option is slower at signing time but a bit faster to verify, as the quadratic residue of the Y coordinate can be computed directly for points represented in
[Jacobian coordinates](https://en.wikibooks.org/wiki/Cryptography/Prime_Curve/Jacobian_Coordinates) (a common optimization to avoid modular inverses
for elliptic curve operations). The two other options require a possibly
expensive conversion to affine coordinates first. This would even be the case if the sign or oddness were explicitly coded (option 2 in the previous design choice). We therefore choose option 3.

**Final scheme** As a result, our final scheme ends up using signatures `(r,s)` where `r` is the X coordinate of a point `R` on the curve whose Y coordinate is a quadratic residue, and which satisfies `sG = R + H(r || P || m)P`.

### Specification

We first describe the verification algorithm, and then the signature algorithm.

The following convention is used, with constants as defined for secp256k1:
* Lowercase variables represent integers or byte arrays.
  * The constant `p` refers to the field size, `0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F`.
  * The constant `n` refers to the curve order, `0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141`.
* Uppercase variables refer to points on the curve with equation `y<sup>2</sup> = x<sup>3</sup> + 7` over the integers modulo `p`.
  * `infinite(P)` returns whether or not `P` is the point at infinity.
  * `x(P)` and `y(P)` are integers in the range `0..p-1` and refer to the X and Y coordinates of a point `P` (assuming it is not infinity).
  * The constant `G` refers to the generator, for which `x(G) = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798` and `y(G) = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8`.
  * Addition of points refers to the usual [elliptic curve group operation](https://en.wikipedia.org/wiki/Elliptic_curve#The_group_law).
  * [Multiplication of an integer and a point](https://en.wikipedia.org/wiki/Elliptic_curve_point_multiplication) refers to the repeated application of the group operation.
* Functions and operations:
  * `||` refers to byte array concatenation.
  * The function `x[i:j]`, where `x` is a byte array, returns a `(j - i)`-byte array with a copy of the `i`-th byte (inclusive) to the `j`-th byte (exclusive) of `x`.
  * The function `bytes(x)`, where `x` is an integer, returns the 32-byte encoding of `x`, most significant byte first.
  * The function `bytes(P)`, where `P` is a point, returns `bytes(0x02 + (y(P) & 1)) || bytes(x(P))`<sup>[5](#footnotes)</sup>.
  * The function `int(x)`, where `x` is a 32-byte array, returns the 256-bit unsigned integer whose most significant byte encoding is `x`.
  * The function `lift_x(x)`, where `x` is an integer in range `0..p-1`, returns the point `P` for which `x(P) = x` and `y(P)` is a quadratic residue modulo `p`, or fails if no such point exists<ref>Given an candidate X coordinate `x` in the range `0..p-1`, there exist either exactly two or exactly zero valid Y coordinates. If no valid Y coordinate exists, then `x` is not a valid X coordinate either, i.e., no point `P` exists for which `x(P) = x`.  Given a candidate `x`, the valid Y coordinates are the square roots of `c = x<sup>3</sup> + 7 mod p` and they can be computed as `y = &plusmn;c<sup>(p+1)/4</sup> mod p` (see [Quadratic residue](https://en.wikipedia.org/wiki/Quadratic_residue#Prime_or_prime_power_modulus)) if they exist, which can be checked by squaring and comparing with `c`. Due to [Euler's criterion](https://en.wikipedia.org/wiki/Euler%27s_criterion) it then holds that `c<sup>(p-1)/2</sup> = 1 mod p`. The same criterion applied to `y` results in `y<sup>(p-1)/2</sup> mod p = &plusmn;c<sup>((p+1)/4)((p-1)/2)</sup> mod p = &plusmn;1 mod p`. Therefore `y = +c<sup>(p+1)/4</sup> mod p` is a quadratic residue and `-y mod p` is not.</ref>. The function `lift_x(x)` is equivalent to the following pseudocode:
     * Let `y = c<sup>(p+1)/4</sup> mod p`.
     * Fail if `c &ne; y<sup>2</sup> mod p`.
     * Return `(r, y)`.
  * The function `point(x)`, where `x` is a 33-byte array, returns the point `P` for which `x(P) = int(x[1:33])` and `y(P) & 1 = int(x[0:1]) - 0x02)`, or fails if no such point exists. The function  `point(x)` is equivalent to the following pseudocode:
     * Fail if (`x[0:1] ≠ 0x02` and `x[0:1] ≠ 0x03`).
     * Set flag `odd` if `x[0:1] = 0x03`.
     * Let `(r, y) = lift_x(x)`; fail if `lift_x(x)` fails.
     * If (flag `odd` is set and `y` is an even integer) or (flag `odd` is not set and `y` is an odd integer):
         * Let `y = p - y`.
     * Return `(r, y)`.
  * The function `hash(x)`, where `x` is a byte array, returns the 32-byte SHA256 hash of `x`.
  * The function `jacobi(x)`, where `x` is an integer, returns the [Jacobi symbol](https://en.wikipedia.org/wiki/Jacobi_symbol) of `x / p`. It is equal to `x<sup>(p-1)/2</sup> mod p` ([Euler's criterion](https://en.wikipedia.org/wiki/Euler%27s_criterion))<sup>[6](#footnotes)</sup>.

#### Verification

Input:
* The public key `pk`: a 33-byte array
* The message `m`: a 32-byte array
* A signature `sig`: a 64-byte array

The signature is valid if and only if the algorithm below does not fail.
* Let `P = point(pk)`; fail if `point(pk)` fails.
* Let `r = int(sig[0:32])`; fail if `r &ge; p`.
* Let `s = int(sig[32:64])`; fail if `s &ge; n`.
* Let `e = int(hash(bytes(r) || bytes(P) || m)) mod n`.
* Let `R = sG - eP`.
* Fail if `infinite(R)`.
* Fail if `jacobi(y(R)) &ne; 1` or `x(R) &ne; r`.

#### Batch Verification

Input:
* The number `u` of signatures
* The public keys `pk<sub>1..u</sub>`: `u` 33-byte arrays
* The messages `m<sub>1..u</sub>`: `u` 32-byte arrays
* The signatures `sig<sub>1..u</sub>`: `u` 64-byte arrays

All provided signatures are valid with overwhelming probability if and only if the algorithm below does not fail.
* Generate `u-1` random integers `a<sub>2...u</sub>` in the range `1...n-1`. They are generated deterministically using a [CSPRNG](https://en.wikipedia.org/wiki/Cryptographically_secure_pseudorandom_number_generator) seeded by a cryptographic hash of all inputs of the algorithm, i.e. `seed = seed_hash(pk<sub>1</sub>..pk<sub>u</sub> || m<sub>1</sub>..m<sub>u</sub> || sig<sub>1</sub>..sig<sub>u</sub> )`. A safe choice is to instantiate `seed_hash` with SHA256 and use [ChaCha20](https://tools.ietf.org/html/rfc8439) with key `seed` as a CSPRNG to generate 256-bit integers, skipping integers not in the range `1...n-1`.
* For `i = 1 .. u`:
** Let `P<sub>i</sub> = point(pk<sub>i</sub>)`; fail if `point(pk<sub>i</sub>)` fails.
** Let `r = int(sig<sub>i</sub>[0:32])`; fail if `r &ge; p`.
** Let `s<sub>i</sub> = int(sig<sub>i</sub>[32:64])`; fail if `s<sub>i</sub> &ge; n`.
** Let `e<sub>i</sub> = int(hash(bytes(r) || bytes(P<sub>i</sub>) || m<sub>i</sub>)) mod n`.
** Let `R<sub>i</sub> = lift_x(r)`; fail if `lift_x(r)` fails.
* Fail if `(s<sub>1</sub> + a<sub>2</sub>s<sub>2</sub> + ... + a<sub>u</sub>s<sub>u</sub>)G &ne; R<sub>1</sub> + a<sub>2</sub>R<sub>2</sub> + ... + a<sub>u</sub>R<sub>u</sub> + e<sub>1</sub>P<sub>1</sub> + (a<sub>2</sub>e<sub>2</sub>)P<sub>2</sub> + ... + (a<sub>u</sub>e<sub>u</sub>)P<sub>u</sub>`.

#### Signing

Input:
* The secret key `d`: an integer in the range `1..n-1`.
* The message `m`: a 32-byte array

To sign `m` for public key `dG`:
* Let `k' = int(hash(bytes(d) || m)) mod n`<ref>Note that in general, taking the output of a hash function modulo the curve order will produce an unacceptably biased result. However, for the secp256k1 curve, the order is sufficiently close to `2<sup>256</sup>` that this bias is not observable (`1 - n / 2<sup>256</sup>` is around `1.27 * 2<sup>-128</sup>`).</ref>.
* Fail if `k' = 0`.
* Let `R = k'G`.
* Let `k = k' ` if `jacobi(y(R)) = 1`, otherwise let `k = n - k' `.
* Let `e = int(hash(bytes(x(R)) || bytes(dG) || m)) mod n`.
* The signature is `bytes(x(R)) || bytes((k + ed) mod n)`.

**Above deterministic derivation of `R` is designed specifically for this signing algorithm and may not be secure when used in other signature schemes.**
For example, using the same derivation in the MuSig multi-signature scheme leaks the secret key (see the [MuSig paper](https://eprint.iacr.org/2018/068) for details).

Note that this is not a `unique signature` scheme: while this algorithm will always produce the same signature for a given message and public key, `k` (and hence `R`) may be generated in other ways (such as by a CSPRNG) producing a different, but still valid, signature.

### Optimizations

Many techniques are known for optimizing elliptic curve implementations. Several of them apply here, but are out of scope for this document. Two are listed below however, as they are relevant to the design decisions:

**Jacobi symbol** The function `jacobi(x)` is defined as above, but can be computed more efficiently using an [extended GCD algorithm](https://en.wikipedia.org/wiki/Jacobi_symbol#Calculating_the_Jacobi_symbol).

**Jacobian coordinates** Elliptic Curve operations can be implemented more efficiently by using [Jacobian coordinates](https://en.wikibooks.org/wiki/Cryptography/Prime_Curve/Jacobian_Coordinates). Elliptic Curve operations implemented this way avoid many intermediate modular inverses (which are computationally expensive), and the scheme proposed in this document is in fact designed to not need any inversions at all for verification. When operating on a point `P` with Jacobian coordinates `(x,y,z)` which is not the point at infinity and for which `x(P)` is defined as `x / z<sup>2</sup>` and `y(P)` is defined as `y / z<sup>3</sup>`:
* `jacobi(y(P))` can be implemented as `jacobi(yz mod p)`.
* `x(P) &ne; r` can be implemented as `x &ne; z<sup>2</sup>r mod p`.

## Applications

There are several interesting applications beyond simple signatures.
While recent academic papers claim that they are also possible with ECDSA, consensus support for Schnorr signature verification would significantly simplify the constructions.

### Multisignatures and Threshold Signatures

By means of an interactive scheme such as [MuSig](https://eprint.iacr.org/2018/068), participants can produce a combined public key which they can jointly sign for. This allows n-of-n multisignatures which, from a verifier's perspective, are no different from ordinary signatures, giving improved privacy and efficiency versus `CHECKMULTISIG` or other means.

Further, by combining Schnorr signatures with [Pedersen Secret Sharing](https://link.springer.com/content/pdf/10.1007/3-540-46766-1_9.pdf), it is possible to obtain [an interactive threshold signature scheme](http://cacr.uwaterloo.ca/techreports/2001/corr2001-13.ps) that ensures that signatures can only be produced by arbitrary but predetermined sets of signers. For example, k-of-n threshold signatures can be realized this way. Furthermore, it is possible to replace the combination of participant keys in this scheme with MuSig, though the security of that combination still needs analysis.

### Adaptor Signatures

[Adaptor signatures](https://download.wpsoftware.net/bitcoin/wizardry/mw-slides/2018-05-18-l2/slides.pdf) can be produced by a signer by offsetting his public nonce with a known point `T = tG`, but not offsetting his secret nonce.
A correct signature (or partial signature, as individual signers' contributions to a multisignature are called) on the same message with same nonce will then be equal to the adaptor signature offset by `t`, meaning that learning `t` is equivalent to learning a correct signature.
This can be used to enable atomic swaps or even [general payment channels](https://eprint.iacr.org/2018/472) in which the atomicity of disjoint transactions is ensured using the signatures themselves, rather than Bitcoin script support. The resulting transactions will appear to verifiers to be no different from ordinary single-signer transactions, except perhaps for the inclusion of locktime refund logic.

Adaptor signatures, beyond the efficiency and privacy benefits of encoding script semantics into constant-sized signatures, have additional benefits over traditional hash-based payment channels. Specifically, the secret values `t` may be reblinded between hops, allowing long chains of transactions to be made atomic while even the participants cannot identify which transactions are part of the chain. Also, because the secret values are chosen at signing time, rather than key generation time, existing outputs may be repurposed for different applications without recourse to the blockchain, even multiple times.

### Blind Signatures

Schnorr signatures admit a very [simple **blind signature** construction](https://www.math.uni-frankfurt.de/~dmst/research/papers/schnorr.blind_sigs_attack.2001.pdf) which is a signature that a signer produces at the behest of another party without learning what he has signed.
These can for example be used in [Partially Blind Atomic Swaps](https://github.com/jonasnick/scriptless-scripts/blob/blind-swaps/md/partially-blind-swap.md), a construction to enable transferring of coins, mediated by an untrusted escrow agent, without connecting the transactors in the public blockchain transaction graph.

While the traditional Schnorr blind signatures are vulnerable to [Wagner's attack](https://www.iacr.org/archive/crypto2002/24420288/24420288.pdf), there are [a number of mitigations](https://www.math.uni-frankfurt.de/~dmst/teaching/SS2012/Vorlesung/EBS5.pdf) which allow them to be usable in practice without any known attacks. Nevertheless, more analysis is required to be confident about the security of the blind signature scheme.

## Test Vectors and Reference Code

For development and testing purposes, we provide a [collection of test vectors in CSV format](/protocol/forks/schnorr/bip-schnorr/test-vectors.csv) and a naive but highly inefficient and non-constant time [pure Python 3.7 reference implementation of the signing and verification algorithm](/protocol/forks/schnorr/bip-schnorr/reference.py).
The reference implementation is for demonstration purposes only and not to be used in production environments.

## Footnotes

1. More precisely they are ***strongly** unforgeable under chosen message attacks* (SUF-CMA), which informally means that without knowledge of the secret key but given a valid signature of a message, it is not possible to come up with a second valid signature for the same message.  A security proof in the random oracle model can be found for example in [a paper by Kiltz, Masny and Pan](https://eprint.iacr.org/2016/191), which essentially restates [the original security proof of Schnorr signatures by Pointcheval and Stern](https://www.di.ens.fr/~pointche/Documents/Papers/2000_joc.pdf) more explicitly. These proofs are for the Schnorr signature variant using `(e,s)` instead of `(R,s)` (see Design above). Since we use a unique encoding of `R`, there is an efficiently computable bijection that maps `(R, s)` to `(e, s)`, which allows to convert a successful SUF-CMA attacker for the `(e, s)` variant to a successful SUF-CMA attacker for the `(r, s)` variant (and vice-versa). Furthermore, the aforementioned proofs consider a variant of Schnorr signatures without key prefixing (see Design above), but it can be verified that the proofs are also correct for the variant with key prefixing. As a result, the aforementioned security proofs apply to the variant of Schnorr signatures proposed in this document.
2. A limitation of committing to the public key (rather than to a short hash of it, or not at all) is that it removes the ability for public key recovery or verifying signatures against a short public key hash. These constructions are generally incompatible with batch verification.
3. Since `p` is odd, negation modulo `p` will map even numbers to odd numbers and the other way around. This means that for a valid X coordinate, one of the corresponding Y coordinates will be even, and the other will be odd.
4. A product of two numbers is a quadratic residue when either both or none of the factors are quadratic residues. As `-1` is not a quadratic residue, and the two Y coordinates corresponding to a given X coordinate are each other's negation, this means exactly one of the two must be a quadratic residue.
5. This matches the `compressed` encoding for elliptic curve points used in Bitcoin already, following section 2.3.3 of the [SEC 1](http://www.secg.org/sec1-v2.pdf) standard.
6. For points `P` on the secp256k1 curve it holds that `jacobi(y(P)) &ne; 0`.

## Acknowledgements

This document is the result of many discussions around Schnorr based signatures over the years, and had input from Johnson Lau, Greg Maxwell, Jonas Nick, Andrew Poelstra, Tim Ruffing, Rusty Russell, and Anthony Towns.
