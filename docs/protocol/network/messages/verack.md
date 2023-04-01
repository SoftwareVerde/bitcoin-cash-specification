# Handshake: Version Acknowledgement ("verack")

The `verack` message is sent in reply to a [`version`](/protocol/network/messages/version) message.
Sending a `verack` in response to a `version` message indicates to the remote that its connection and version has been accepted.

There is no version negotiation functionality between nodes; therefore if the node does not accept the version supplied by the remote then the node disconnects instead of responding with a `verack`.

## Message Format

This message has no contents.
