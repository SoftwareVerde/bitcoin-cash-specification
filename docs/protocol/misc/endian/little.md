# Little-Endian

Little-endian byte ordering is widely used throughout the Bitcoin Cash protocol, particularly for integers.

In little-endian byte ordering, the least significant byte is first, following the second-least-significant, and so on.
This is often the opposite of what people consider "natural" for numbers, despite being fairly common in computer hardware.

For example, the value 5,000, when represented in little-endian format, would be the byte 0x88 followed by 0x13, while 5,001 would be the byte 0x89 followed by 0x13.
Contrast this with [big-endian](/protocol/misc/endian/big).

For information, see [Endianness](https://en.wikipedia.org/wiki/Endianness).