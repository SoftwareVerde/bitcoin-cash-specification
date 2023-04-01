# CashAddr encoding

CashAddr encoding is an address format used in Bitcoin Cash. This is a Base32 encoding format that prevents confusion with [Base58Check](/protocol/blockchain/encoding/base58check) legacy address encoding also used by Bitcoin-BTC. The goal of the encoding is to make it easier to copy and to share information, by using a QR code for instance.

A Cash Address consists of:

- A **prefix** which is human-readable.
- A **separator** (`:`).
- A Base32 **payload** which contains a version byte and the data (or hash).
- A Base32 **checksum**.

This format reuses the work done for Bech32 (see [BIP173](https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki)) and is similar in some aspects, but improves on others. See the [original specification](https://github.com/bitcoincashorg/bitcoincash.org/blob/master/spec/cashaddr.md) for more details.

## Prefix

The prefix is a human-readable part of the address which indicates the network on which the addess is valid, or the metaprotocol used. It can only contain ASCII characters.

There are 3 prefixes used in Bitcoin Cash to indicate the network:

| Network | Prefix        |
| ------- | ------------- |
| Mainnet | `bitcoincash` |
| Testnet | `bchtest`     |
| Regtest | `bchreg`      |

The prefix can also indicate for which metaprotocol the addres must be used. For instance, Simple Ledger Protocol (SLP) addresses are required to begin with `simpleledger` in order to avoid sending SLP tokens to a non-SLP wallet.

The prefix is always followed by the separator `:`.

When presented to users, the prefix and the separator may be omitted as it is part of the checksum computation. 

## Base32

CashAddr uses Base32 to encode information. The symbols used in CashAddr Base32 are the lowercase alphanumeric characters excluding `1`, `b`, `i`, and `o`. Uppercase characters are also valid to enable efficient QR code encoding ([see spec](https://github.com/bitcoincashorg/bitcoincash.org/blob/master/spec/cashaddr.md#uppercaselowercase)). However, any mixture of lowercase and uppercase characters must be rejected.

Base32 alphabet:

```
qpzry9x8gf2tvdw0s3jn54khce6mua7l
```

Base32 symbol chart:

| Value | Character | Value | Character |
| ----- | --------- | ------| --------- | 
| 0     | q         | 16    | s         | 
| 1     | p         | 17    | 3         | 
| 2     | z         | 18    | j         |
| 3     | r         | 19    | n         | 
| 4     | y         | 20    | 5         |
| 5     | 9         | 21    | 4         |
| 6     | x         | 22    | k         |
| 7     | 8         | 23    | h         |
| 8     | g         | 24    | c         |
| 9     | f         | 25    | e         |
| 10    | 2         | 26    | 6         |
| 11    | t         | 27    | m         |
| 12    | v         | 28    | u         | 
| 13    | d         | 29    | a         | 
| 14    | w         | 30    | 7         | 
| 15    | 0         | 31    | l         | 

## Version bytes

The version byte is divided into 3 parts: 

- The most significant bit is reserved and must be `0`.

- The 4 next bits indicate the type of address: `0b000` for P2PKH, and `0b001` for P2SH.

- The last 3 bits indicate the size of the data. This ensures that it is possible to check that the length of the address is correct. The size options are:

    | Size bits | Data size (bytes) |
    | --------- | ----------------- |
    | 0b000     | 20                |
    | 0b001     | 24                |
    | 0b010     | 28                |
    | 0b011     | 32                |
    | 0b100     | 40                |
    | 0b101     | 48                |
    | 0b110     | 56                |
    | 0b111     | 64                |

For a legacy 20-byte (160-bit) hash, the follwoing version bytes are currently allowed:

| Type          | Type bits  | Version byte | Address prefix |
| ------------- | ---------- | -------------| -------------- |
| P2PKH address | 0b0000     | 0            | q              |
| P2SH address  | 0b0001     | 5            | p              |

Note that further types will be added as new features are added.

## Checksum

The checksum is a 40 bits [BCH code](https://en.wikipedia.org/wiki/BCH_code) defined over the finite field GF(2^5). It ensures the detection of up to 6 errors in the address and 8 in a row. Combined with the length check, this provides very strong guarantee against errors.

The checksum is computed by the following `polymod` function (written in Python):

```python
def polymod(values):
        c = 1
        for d in values:
            c0 = c >> 35
            c = ((c & 0x07ffffffff) << 5) ^ d
            if (c0 & 0x01):
                c ^= 0x98f2bc8e61
            if (c0 & 0x02):
                c ^= 0x79b76d99e2
            if (c0 & 0x04):
                c ^= 0xf33e5fb3c4
            if (c0 & 0x08):
                c ^= 0xae2eabe2a8
            if (c0 & 0x10):
                c ^= 0x1e4f43e470
        return c ^ 1
```

where `&` is the bitwise AND operator, `^` is the bitwise XOR operator, and `>>` is the bitwise right shift.


## Encoding a Bitcoin Cash address

To encode an address with CashAddr, follow the steps described below:

1. Take the address data, which is usually the hash of a public key (P2PKH) or a redeem script (P2SH), and compute the corresponding version byte. 

2. Concatenate the version byte and the data bytes together (bytewise):

    ```
    payload = version || data
    ```

3. Divide the payload into chunks of 5 bits. The payload is padded to the right with zero bits to complete any unfinished chunk at the end.

4. Compute the checksum by applying `polymod` to the following values:

    a. The lower 5 bits of each character of the prefix. For letters, this corresponds to their position in the alphabet.
    
    b. A zero for the separator (5 zero bits).
    
    c. The payload.
    
    d. Eight zeros as a template for the checksum.
    
5. Encode each chunk of the payload and each chunk of the checksum with Base32. 

    
## Example

The steps to encode a P2PKH address which is valid on the Bitcoin Cash main network are:

1. Take the address data, i.e., the 20-byte hash of the public key: 

    ```
    211b74ca4686f81efda5641767fc84ef16dafe0b
    ```

2. Concatenate the version byte (here `0x00`) and the data bytes together to get the payload:

    ```
    00211b74ca4686f81efda5641767fc84ef16dafe0b
    ```
2. Divide the payload into chunks of 5 bits. In this example, the payload is 168-bit long; therefore, it is padded to the right with **2** zero bits to complete the last chunk. The resulting chunks are:

    ```
    [ 0, 0, 16, 17, 22, 29, 6, 10, 8, 26, 3, 15, 16, 7, 23, 29, 20, 21, 18, 1, 14, 25, 31, 28, 16, 19, 23, 17, 13, 22, 23, 30, 1, 12 ]
    ```
    
3. Compute the checksum by applying `polymod` to the concatenation of:

    a. The lower 5 bits of each character of the prefix `bitcoincash`:
    
    ```
    [ 2, 9, 20, 3, 15, 9, 14, 3, 1, 19, 8 ]
    ```
    
    b. A zero for the separator:
    
    ```
    [ 0 ]
    ```
        
    c. The payload chunks:
    
    ```
    [ 0, 0, 16, 17, 22, 29, 6, 10, 8, 26, 3, 15, 16, 7, 23, 29, 20, 21, 18, 1, 14, 25, 31, 28, 16, 19, 23, 17, 13, 22, 23, 30, 1, 12 ]
    ```
    
    d. The template of the checksum:
    
    ```
    [ 0, 0, 0, 0, 0, 0, 0, 0 ]
    ```
    
    The checksum is:
    
    ```
    [ 28, 10, 17, 3, 2, 3, 3, 28 ]
    ```
    
4. Encoded with Base32, the payload and the checksum are, respectively, `qqs3kax2g6r0s8ha54jpwelusnh3dkh7pv` and `u23rzrru`. The resulting address is:

    ```
    bitcoincash:qqs3kax2g6r0s8ha54jpwelusnh3dkh7pvu23rzrru
    ```
