# Signatures

Bitcoin transaction generally require at least one signature in order to be valid.
Signatures prove that the intended recipient(s) of the funds being spent were involved in the creation of the transaction.
Each signature is generated using a [private key](/protocol/blockchain/cryptography/keys) and indicates that the owner of that private key approves of certain data in the transaction.
This page describes how these signature are generated, given data to be signed and a private key.
For details on what data is signed when signing a transaction and how the signature is formatted, see [Transaction Signing](/protocol/blockchain/transaction/transaction-signing).

Bitcoin Cash permits two algorithms for transaction signatures: [ECDSA](#ecdsa-signatures) and [Schnorr](#schnorr-signatures).

## ECDSA Signatures

ECDSA, as defined in [RFC 6979](https://tools.ietf.org/html/rfc6979), can be thought of as taking three input parameters: the private key, the message to be signed, and a random value, **k**, taken from the [same domain as a private key](/protocol/blockchain/cryptography/keys#private-key-generation), `[1, n-1]`.

Generally with ECDSA, the message used is a hash of the data that is intended to be signed.
In the case of Bitcoin Cash, this is the hash of the transaction [preimage](/protocol/blockchain/transaction/transaction-signing#preimage-format) for the context in which the signature will be provided (i.e. for a given position in a script).
It is also common, and recommended, to use a **deterministic k** value (defined in [RFC 6979, section 3](https://tools.ietf.org/html/rfc6979#section-3)), which is dependent on the private key and the message being signed.
Using a deterministic k value guarantees that a different k will never be used to sign an identical message, a mistake which would reveal the user's private key.
However, since it is impossible to know the method used to generate k without the user's private key, it is impossible to enforce the use of this method.

The output of ECDSA is two values, **r** and **s** which can be used with the public key and message to verify the authenticity of the signature.
However, there are technically two valid s value that are possible, which are additive inverses (i.e. `s<sub>1</sub> + s<sub>2</sub> (mod p) = 0 (mod p)`).
By convention, and since [HF-20171113](/protocol/forks/hf-20171113), the lower s value must be used (this is known as the "LOW_S" rule).

## Schnorr Signatures

Schnorr signatures have been accepted in Bitcoin Cash since [HF-20190515](/protocol/forks/hf-20190515).
Details on the implementation of Schnorr used in Bitcoin Cash can be found [here](/protocol/forks/2019-05-15-schnorr).
Of particular importance are the following points:

- Pre-existing Public and Private Keys are valid for generating Schnorr signatures.
- Following activation of Schnorr signatures, all 64-byte signatures passed to OP_CHECKDATASIG/VERIFY and all 65-byte signatures passed to OP_CHECKSIG/VERIFY are interpretted as Schnorr signatures.
  65-byte signatures passed to OP_CHECKMULTISIG/VERIFY will trigger script failure.
- Bitcoin Cash uses the (r, s) variant of Schnorr, instead of the (e, s) variant, with an altered approach from that originally proposed by Pieter Wuille.
- Both random and deterministic k values are considered secure, though care must be taken with deterministic k values to avoid conflicts with deterministic ECDSA k values.

