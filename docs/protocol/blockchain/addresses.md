# Address Types

Addresses are commonly used identifiers that act as a shorthand for who can spend a given output.
Since Bitcoin Cash [transactions](/protocol/blockchain/transaction) do not inherently have a concept of accounts with balances, it is not always easy (or even possible) to determine which unspent outputs are spendable by a given person.
However, the [standard scripts](/protocol/blockchain/transaction/locking-script#standard-scripts) were designed to provide a straightforward structure that can be used to identify transactions that spendable in similar ways.
In most cases, the address contains all of the information necessary to create a transaction output that is spendable by the owner of the address.
Due to this and their compactness, addresses are the most common way to specify to others how ("where") they can receive funds.

Raw addresses are rarely used outside of scripts, though, as they lack context and redundancy.
Instead, addresses are typically encoded using the [Base58Check](/protocol/blockchain/encoding/base58check) or [CashAddr](/protocol/blockchain/encoding/cashaddr) formats to ensure they are received and interpreted correctly.
These encodings include checksums as well as information about the type of address being encoded.
CashAddr was created after Base58Check (also referred to as legacy encoding) to avoid conflicts with pre-existing BTC address.

## Pay to Public Key Hash (P2PKH) Addresses

[P2PKH](/protocol/blockchain/transaction/locking-script#pay-to-public-key-hash-p2pkh) addresses encode the hash of the public key that is locking the output (i.e. `RIPEMD-160(SHA-256(publicKey))`).
Mainnet P2PKH addresses always start with `1` in Base58Check encoding and `q` in CashAddr encoding:

    Base58Check:  1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa
    CashAddr:     bitcoincash:qp3wjpa3tjlj042z2wv7hahsldgwhwy0rq9sywjpyy

The following diagram show the full creation process for a P2PKH address:

```mermaid
graph LR
PrivK["Private Key"] ==>PubK[Public key]
PubK == SHA256 and RIPEMD160 ==> PubKH[Public Key Hash]
PubKH ==> Address
Address ==> PubKH
style PubK fill:#F06,stroke:#333,stroke-width:2px;
style PrivK fill:#B06,stroke:#333,stroke-width:8px;
style PubKH fill:#0F6,stroke:#333,stroke-width:2px;
style Address fill:#0F6,stroke:#333,stroke-width:2px;
```

## Pay to Script Hash (P2SH) Addresses

[P2SH](/protocol/blockchain/transaction/locking-script#pay-to-script-hash-p2sh) addresses encode the redeem script hash (i.e. `RIPEMD-160(redeemScript)`).
Mainnet P2SH addresses always start with `3` in Base58Check encoding and `p` in CashAddr encoding.

    Base58Check:  3N5i3Vs9UMyjYbBCFNQqU3ybSuDepX7oT3
    CashAddr:     bitcoincash:pr0662zpd7vr936d83f64u629v886aan7c77r3j5v5

## Multisig Addresses

Multisig addresses are occasionally referenced despite there not being a specific process for creating them.
This is because the addresses being referred to are actually P2SH addresses for redeem scripts that perform [multisignature](/protocol/blockchain/cryptography/multisignature) validation.
As such, they look exactly like P2SH addresses and are indistinguishable from them until the script is known and inspected.
Moreover, outputs created using multsig addresses use the P2SH script format, not the [Multisig (P2MS)](/protocol/blockchain/transaction/locking-script#multisig-p2ms) script format.

Alternatively, with the advent of [Schnorr signatures](/protocol/blockchain/cryptography/signatures#schnorr-signatures) in BCH, it is also possible perform n-of-n multisignature locking and unlocking using [aggregated keys and signatures](/protocol/blockchain/cryptography/multisignature#private-multisignature).
Only a single signature is produces, regardless of the number of parties involved, reducing the cost of multisignature validation and minimizing transaction size.
This also means it could fit in a P2PKH (or P2PK) script, and therefore have a typical address of that type.
This technique is newer, however, and not as widely implemented as the P2SH method.