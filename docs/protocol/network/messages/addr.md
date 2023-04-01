<div class="cwikmeta">{
"title":"ADDR",
"related":["/protocol","/protocol/network/messages/getaddr"]
}</div>

# Response: Addresses ("addr")

Provide information about other prospective P2P protocol peers.  Peers SHOULD not send this message unsolicited (see [`getaddr`](/protocol/network/messages/getaddr)), and nodes that receive an unsolicited `addr` message MUST ignore it.  This behavior helps prevent eclipse and partitioning attacks by not allowing an attacker to aggressively seed peer connection tables with its own nodes.

## Message Format

| Field | Length | Format | Description |
|--|--|--|--|
| peer count | variable | [variable length integer](/protocol/formats/variable-length-integer) | The number of peers whose connection information is being sent in this message. |
| peer network addresses | `peer_count` * 30 | `peer_count` [network addresses](/protocol/formats/network-address) | The peer information for each of the peers being transmitted. |

