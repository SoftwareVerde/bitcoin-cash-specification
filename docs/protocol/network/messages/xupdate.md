<div class="cwikmeta">{
"title":"XUPDATE",
"related":["/protocol/network/messages","/protocol/network/messages/xversion"]
}</div>

# Handshake Extension: XVersion (“xversion”)

This message notifies a peer about changes to protocol parameters.
It follows the same format as [`xversion`](/protocol/network/messages/xversion) protocol parameters.
Implementations SHOULD only send changed parameters, rather than every parameter.
Note that some `xversion` parameters are not changeable and therefore will be ignored if they appear in this message.

See the [xversion fields](/protocol/network/messages/xversion#xversion-fields) for detailed information about each parameter.

## Message Format

| Field | Length | Format | Description |
|--|--|--|--|
| number of values | variable | [variable length integer](/protocol/formats/variable-length-integer) | The number of values being sent. |
| values | variable | `number_of_values` * [xversion values](/protocol/network/messages/xversion#xversion-value-format) | The list of values to communicate. |


### Support
Supported by: **Bitcoin Unlimited**
