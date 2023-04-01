# Big-Endian

Big-endian byte ordering, also referred to as network byte ordering, is used in many places in the Bitcoin Cash protocol.  While not always called out explicitly in this specification, it is called out when readers might be inclined to expect little-endian byte ordering.

In big-endian byte ordering, the most significant byte is first, following the second-most-significant, and so on.
This is what many would consider the "natural" order in most circumstances.

For example, the value 5,000, when represented in big-endian format, would be the byte 0x13 followed by 0x88, while 5,001 would be the byte 0x13 followed by 0x89.
Contrast this with [little-endian](/protocol/misc/endian/little).

For information, see [Endianness](https://en.wikipedia.org/wiki/Endianness).