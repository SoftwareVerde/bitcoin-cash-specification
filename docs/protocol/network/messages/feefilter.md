# Request: Fee Filter (“feefilter”)

Requests that the recipient withhold transactions that provide less than the given threshold of fees, in satoshis per kilobyte (1000 bytes).

The recipient node may, but is not required to, begin to perform this filtering and send only transactions that have fees at or above this threshold to the sender.

Defined in [BIP-133](/protocol/forks/bip-0133).

## Message Format

| Field | Length | Format | Description |
|--|--|--|--|
|  minimum fee per byte  | 8 bytes | unsigned integer<sup>[(LE)](/protocol/misc/endian/little)</sup> | The minimum number of satoshis, per 1000 bytes, desired by the sender in fees. |
