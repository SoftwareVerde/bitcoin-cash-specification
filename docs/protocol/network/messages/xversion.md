<div class="cwikmeta">{
"title":"XVERSION",
"related":["/protocol/network/messages","/protocol/network/messages/xupdate","/protocol/network/messages/xverack"]
}</div>

# Handshake Extension: XVersion (“xversion”) 

This message notifies a peer about extended protocol parameters.  This message MAY be sent during connection initialization.  If sent, it MUST be sent immediately subsequent to the receipt of the [`verack`](/protocol/network/messages/verack) message, and before other non-initialization messages are sent.

## Message Format

| Field | Length | Format | Description |
|--|--|--|--|
| number of values | variable | [variable length integer](/protocol/formats/variable-length-integer) | The number of values being sent. |
| values | variable | `number_of_values` * [xversion values](#xversion-value-format) | The list of values to communicate. |

### XVersion Value Format

| Field | Length | Format | Description |
|--|--|--|--|
| field | variable | [variable length integer](/protocol/formats/variable-length-integer) | Indicates the field type of the value to follow.  See [XVersion Fields](#xversion-fields). |
| size of value | variable | [variable length integer](/protocol/formats/variable-length-integer) | The size of the value to follow. |
| value | `size_of_value` bytes | bytes | The value for the preceding field type (`key`).  The format of the value is defined by the `field`, but must be the specified number of bytes.  |

#### XVersion Fields

XVersion field identifiers are 32 bits and split into a 16 bit prefix and 16 bit suffix.  Each development group is assigned a prefix so that new identifiers do not accidentally conflict.  Once a field identifier is created by group A, it should be used by other software both to receive that information from A and to present that information to other software.  Therefore, group A **MUST NOT** change the syntax or semantics of a field once defined.  To change a field, create a new identifier and deprecate (by no longer using the original identifier).

#### Prefix and Suffix Assignments

##### Prefix Assignments
|    Group                | Value |
|-------------------------|-------|
| Reserved for versioning |   0   |
| Bitcoin Cash Node       |   1   |
| Bitcoin Unlimited       |   2   |

See [xversionkeys.dat](https://github.com/BitcoinUnlimited/BitcoinUnlimited/blob/bucash1.7.0.0/src/xversionkeys.dat) for the most up-to-date field definitions defined by the BitcoinUnlimited full node.
Note that:
* *u64c* refers to a [variable length integer](/protocol/formats/variable-length-integer).
* *Changeable* fields MAY be changed during the course of a connection via the [`xupdate`](/protocol/network/messages/xupdate) message.

### Support

Supported by: **Bitcoin Unlimited**
