<div class="cwikmeta" style="visibility:hidden;">
{
"title":"PING",
"related":["/protocol/network/messages/pong.md"]
} </div>

# Request: Ping ("ping")

Connection keep-alive, "aliveness" and latency discovery.

If a node receives a `ping` message, it replies as quickly as possible with a [`pong`](/protocol/network/messages/pong.md) message with the provided *nonce*.


## Message Format

| Field | Length | Format | Description |
|--|--|--|--|
|  nonce  | 8 bytes | unsigned 64 bit integer<sup>[(LE)](/protocol/misc/endian/little.md)</sup> | An arbitrary value provided to connect the ping message with the `pong` reply. |
