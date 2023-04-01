# Base58check encoding

In Bitcoin Cash, an encoding used for keys and addresses is **Base58Check**. This is a Base58 encoding format that unambiguously encodes the type of data in the first few characters (the *version*) and includes an error detection code in the last few characters (the *checksum*). Its goal is to make it easier to copy and to share information, by using a QR code for instance.

To encode a Bitcoin Cash address, it is however recommended to use the CashAddr encoding instead, because it prevents confusion with Bitcoin-BTC addresses.

## Base58

Base58's goal is to avoid copy error and enable doublecliking selection. That is why it uses all the alphanumeric symbols excluding `0`, `O`, `I` and `l`, these last characters being hard to ditinguish from one another in some fonts.

Base58 alphabet:

```
123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz
```

Base58 symbol chart:

| Value | Character | Value | Character | Value | Character | Value | Character |
| ----- | --------- | ------| --------- | ------| --------- | ------| --------- |
| 0     | 1         | 15    | G         | 30    | X         | 45    | n         |
| 1     | 2         | 16    | H         | 31    | Y         | 46    | o         |
| 2     | 3         | 17    | J         | 32    | Z         | 47    | p         |
| 3     | 4         | 18    | K         | 33    | a         | 48    | q         |
| 4     | 5         | 19    | L         | 34    | b         | 49    | r         |
| 5     | 6         | 20    | M         | 35    | c         | 50    | s         |
| 6     | 7         | 21    | N         | 36    | d         | 51    | t         |
| 7     | 8         | 22    | P         | 37    | e         | 52    | u         |
| 8     | 9         | 23    | Q         | 38    | f         | 53    | v         |
| 9     | A         | 24    | R         | 39    | g         | 54    | w         | 
| 10    | B         | 25    | S         | 40    | h         | 55    | x         |
| 11    | C         | 26    | T         | 41    | i         | 56    | y         |
| 12    | D         | 27    | U         | 42    | j         | 57    | z         |
| 13    | E         | 28    | V         | 43    | k         |
| 14    | F         | 29    | W         | 44    | m         |


## Version bytes

In the Base58Check encoding, the version byte indicates the type of the data encoded. The mainnet version bytes are:

| Type                         | Hex value  | Decimal value | Base58 prefix |
| ---------------------------- | ---------- | --------------| ------------- |
| P2PKH address                | 0x00       | 0             | 1             |
| P2SH address                 | 0x05       | 5             | 3             |
| Private key (WIF)            | 0x80       | 128           | 5             |
| Private key (WIF-compressed) | 0x80       | 128           | K or L        |
| Extended private key         | 0x0488ade4 | 76066276      | xpub          |
| Extended public key          | 0x0488b21e | 76067358      | xprv          |

The testnet version bytes are:

| Type                                 | Hex value  | Decimal value | Base58 prefix |
| ------------------------------------ | ---------- | --------------| ------------- |
| Testnet P2PKH address                | 0x6f       | 111           | m or n        |
| Testnet P2SH address                 | 0xc4       | 196           | 2             |
| Testnet private key (WIF)            | 0xef       | 239           | 9             |
| Testnet private key (WIF-compressed) | 0xef       | 239           | c             |
| Testnet extended private key         | 0x043587cf | 70617039      | tpub          |
| Testnet extended public key          | 0x04358394 | 70615956      | tprv          |

## Encoding

Base58Check is used to encode a **payload** and a **version** byte. It is done by following the steps described below.

1. Take the version byte and the payload bytes, and concatenate them together (bytewise):

    ```
    version || payload
    ```

2. Compute the checksum by taking the first four bytes of the double SHA256 hash function of this concatenation.

    ```
    checksum = SHA256( SHA256( version || payload ) )[:4]
    ```

3. Concatenate all three of them together: 

    ```
    version || payload || checksum
    ```

4. Encode the result with Base58. Note that each leading zero bytes are encoded with the character `1` which is added to the string.

    ```
    Base58( version || payload || checksum )
    ```

## Encoding a private key (Wallet Import Format)

Private keys in Bitcoin Cash are usually encoded with Base58Check. This is known as *Wallet Import Format* (WIF). 

Steps to encode a private key:

1. Take a private key, i.e., a number between 0 and the order of the generator point (G) of secp256k1. Let's consider the following private key (32-byte array):

    ```
    1e99423a4ed27608a15a2616a2b0e9e52ced330ac530edcc32c8ffc6a526aedd
    ```
    
2. Take the version byte corresponding to it (`0x80` for mainnet, `0xef` for testnet), and concatenate them together:

    ```
    801e99423a4ed27608a15a2616a2b0e9e52ced330ac530edcc32c8ffc6a526aedd
    ```
    
3. Compute the checksum by performing the double SHA256 on it, and by taking the first four bytes of this hash:

    ```
    SHA256( SHA256( 801e99423a4ed27608a15a2616a2b0e9e52ced330ac530edcc32c8ffc6a526aedd ) ) = c47e83ffafda3ba4396e1bc6a648515e5fc9aa95910af6a4429537b87fb7b474
    ```
    
4. Concatenate the result from step 2 and the checksum together:

    ```
    801e99423a4ed27608a15a2616a2b0e9e52ced330ac530edcc32c8ffc6a526aeddc47e83ff
    ```
    
5. Encode it with Base58. The result is the Wallet Import Format, or WIF, of the private key. If it is a mainnet (uncompressed) private key, it will always start with a `5`.

    ```
    5J3mBbAH58CpQ3Y5RNJpUKPE62SQ5tfcvU2JpbnkeyhfsYB1Jcn
    ```
    
If you want to derive a compressed public key from this private key, which is usually done in every modern wallets, simply add the prefix `0x01` to the private key bytes:

```
1e99423a4ed27608a15a2616a2b0e9e52ced330ac530edcc32c8ffc6a526aedd01
```

and follow the steps (2-5) described above, to get the encoded private key: 

```
KxFC1jmwwCoACiCAWZ3eXa96mBM6tb3TYzGmf6YwgdGWZgawvrtJ
```

It is known as the WIF-compressed format. Even if the private key is not compressed, the wallet will take this encoding into account and will derive a compressed public key from it. Note that WIF-compressed private keys always start with a `K` or a `L`. 

## Encoding a Bitcoin Cash address

Addresses in Bitcoin Cash can sometimes be encoded with Base58Check. These encoded addresses are called *legacy address*. Even if this format is still supported by various wallets, it is strongly recommended to use CashAddr encoding instead.

Steps to encode a legacy address:

1. Take an address payload, i.e., the hash of a public key (P2PKH) or a redeem script (P2SH) which is a 20-byte array:

    ```
    211b74ca4686f81efda5641767fc84ef16dafe0b
    ```
    
2. Take the corresponding `version` byte (`0x00` for mainnet P2PKH, `0x05` for mainnet P2SH, `0x6f` for testnet P2PKH, `0xc4` for testnet P2SH), and concatenate them together. In our case, this is a mainnet P2PKH address:

    ```
    00211b74ca4686f81efda5641767fc84ef16dafe0b
    ```
    
3. Compute the checksum by performing the double SHA256 on it, and by taking the first four bytes of this hash:

    ```
    SHA256( SHA256( 00211b74ca4686f81efda5641767fc84ef16dafe0b ) ) = 388c8d1d3f70ec351abf400fadf7756418e6b3835c01fe78206b39ec1ab8a37a
    ```
    
4. Concatenate the result from step 2 and the checksum together:

    ```
    00211b74ca4686f81efda5641767fc84ef16dafe0b388c8d1d
    ```
    
5. Encode it with Base58. Note that each leading zero byte must be encoded with the prefix `1` which is appended to the beginning of the string. Thus, if it is a mainnet P2PKH legacy address (`0x00` version byte), it will always start with a `1`.

    ```
    1424C2F4bC9JidNjjTUZCbUxv6Sa1Mt62x
    ```
    
**Important notice.** Please do not use this encoding for P2SH address. It can (and should) be deactivated by wallets in order to prevent to send funds to P2SH-embedded SegWit addresses, which are not supported by the Bitcoin Cash protocol.
