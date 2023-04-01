<div class="cwikmeta">{
"title":"REJECT",
"related":["/protocol"]
}</div>

# Response: Reject ("reject")

Notifies peer that a received message is invalid.

## Message Format

| Field | Length | Format | Description |
|--|--|--|--|
| rejected message type | variable | [variable length string](/protocol/formats/variable-length-string) | The [command string](/protocol/network/messages#command-string) of the message that is being rejected (e.g. "tx"). |
| rejection code | 1 byte | [rejection code](#rejection-codes) | A code indicating why the message was rejected. |
| rejection reason\* | variable | [variable length string](/protocol/formats/variable-length-string) | A description of why the message was rejected. |
| rejection data | variable | rejection code specific| Optional extra data provided by rejection codes. For example, those that reject specific objects.  Currently, all rejection codes that use this field fill it with the hash of the object being rejected, such as the transaction ID or block header hash, in which case the field is 32 bytes.

 \* *rejection reason* is a string providing a human language explanation of the reason the message was rejected.
 This string is subject to change so client software **SHOULD NOT** use it programmatically.

#### Rejection Codes

|    Name    | Value | Response To |  Description |
|-------------|-------|---------------|-----------|
| REJECT_MALFORMED | 0x01 | any | Message cannot be deserialized. |
| REJECT_INVALID | 0x10 | BLOCK, TX, FILTERSIZEXTHIN | Block or transaction is invalid, or xthin filter size is too small |
| REJECT_OBSOLETE | 0x11 | VERSION | This node no longer supports your client protocol version |
| REJECT_DUPLICATE | 0x12 | unused | |
| REJECT_NONSTANDARD | 0x40 | TX | Transaction is [non-standard](/protocol/blockchain/transaction-validation/network-level-validation-rules#standard-transactions), or not final as per [BIP68](/protocol/forks/bip-0068). |
| REJECT_DUST  | 0x41 | TX | Transaction has an output that is too small. |
| REJECT_INSUFFICIENTFEE | 0x42 | TX | Transaction does not pay enough in fees to be relayed. |
| REJECT_CHECKPOINT | 0x43 | unused | |
