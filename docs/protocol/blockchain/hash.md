# Hash

A variety of hashing algorithms are used throughout the Bitcoin Cash protocol.
This specification does not explain what hashes are, nor the details of the specific hashing algorithms used, as that is covered well elsewhere.
Instead, this page will focus on which hashing algorithms are used, where they are used, and why they are used there.

## SHA-256
[SHA-256](https://en.wikipedia.org/wiki/SHA-2) is widely used throughout the Bitcoin Cash protocol to identify blocks and transactions along with a variety of purposes in transaction scripts.
The most notable uses of SHA-256 are:

 - Block Hashing (Double SHA-256)
	 - A SHA-256 hash is taken of the block header.
The output hash is then hashed again with SHA-256.
This resultant hash is referred to simply as the block hash and is used as a unique identifier for the block.
	 - This double hash removes the possibility of a [length extension attack](https://en.wikipedia.org/wiki/Length_extension_attack) which a single SHA-256 is vulnerable to.
While this is generally not a problem for Bitcoin Cash since the pre-image (the actual data of the block) is available, it trades a minor amount of inefficiency for confidence that this property of SHA-256 cannot be exploited.
	 - Double SHA-256 has its own Bitcoin [Script](/protocol/blockchain/script) operation for ease-of-use, [OP_HASH256](/protocol/blockchain/script/opcodes/op-hash256)
 - Transaction Hashing (Double SHA-256)
	 - Transactions are also hashed using a double application of SHA-256.
This is referred to as the transaction hash and is used to uniquely identify the transaction.
(NOTE: Historical transaction hashes are not universally unique, there are two sets of two identical coinbase transactions (and thus identical hashes).
Since [BIP-34](/protocol/forks/bip-0034), the block height is now required to be in the coinbase transaction, which drastically reduces the possibility of duplicate transaction hashes in the future.)
	 - The two cases where this occurred are the following transactions which each appear in two blocks:
		 - `D5D27987D2A3DFC724E359870C6644B40E497BDC0589A033220FE15429D88599`
		 - `E3BF3D07D4B0375638D5F1DB5255FE07BA2C4CB067CD81B84EE974B6585FB468`

In contrast to many other protocols, Bitcoin Cash sometimes treats block and transaction hashes as a number, for example when comparing with block difficulty during block validation or mining.
In these situations, the output byte array of the hashing algorithm is interpreted as a 256 bit number in little-endian format, particularly when transmitted over the network.
This is the opposite of standard protocol design, so it may be simpler to think of hashes as byte arrays that occasionally are turned into little-endian numbers, than as numbers with a lot of display/encoding caveats.

## RIPEMD-160
[RIPEMD-160](https://en.wikipedia.org/wiki/RIPEMD) is used in Bitcoin Cash scripts to create short, quasi-anonymous representations of payees for transactions.
Since its brevity is also a potential liability for the anonymity it provides (since shorter hashes generally provide less collision-resistance), it is used in conjunction with SHA-256 when generating an address from a public key.
That is, `(public key) -> SHA-256 -> RIPEMD-160 -> (address)`.
This SHA-256 then RIPEMD-160 process has its own operation for ease-of-use, [OP_HASH160](/protocol/blockchain/script/op-codes/op-hash160).
 ## Murmur

[MurmurHash](https://en.wikipedia.org/wiki/MurmurHash) is used in Bitcoin to support [Bloom filters](https://en.wikipedia.org/wiki/Bloom_filter).
The specific version used is the MurmurHash version 3 (32-bit), with the first hash initialized to `(numberOfHashesRequired * 0xFBA4C795L + nonce)` where `nonce` is a randomly chosen 32-bit unsigned integer.
