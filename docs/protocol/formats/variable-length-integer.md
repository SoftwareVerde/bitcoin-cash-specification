# Compact Variable Length Integer

A variable-width data format for unsigned integers allowing a more compact representation for smaller values.  This is sometimes referred to as "compact size" or "var int"\*.  

\* - Caution should be used when refering to this integer format as "var int" (or "VarInt"), however, in that it may create an ambiguity. The "Core" family of software (BCHN, BU, and Flowee) all have an internal "VARINT" format that is distinct from this integer format. In that "Core" lineage of software, COMPACTSIZE or CompactSize is used to refer to the protocol's variable length integer format, while "VarInt" refers specifically to their internal variable length integer format and is *not* a part of the Bitcoin Cash P2P protocol.

## Format

Numbers are encoded with the first rule that applies of the following:

* If the number < 253 (0xFD), store it in 1 byte, left-padded with zeros.
* If the number fits in 16 bits (but is greater than 252), store it in 3 bytes: a 1-byte value 253 (0xFD) followed by the 2 byte little-endian number.

| Byte Index | C-Style Calculation |
|-------------|------------------------|
| 0 | 0xFD |
| 1 | value & 255 |
| 2 | value >> 8  |

* If the number fits in 32 bits (but not 8 or 16), store it in 5 bytes: a 1-byte value 254 (0xFE) followed by the 4 byte little-endian number

| Byte Index | C-Style Calculation |
|-------------|------------------------|
| 0 | 0xFE |
| 1 | value & 255 |
| 2 | (value >> 8) & 255  |
| 3 | (value >> 16) & 255  |
| 4 | (value >> 24) & 255  |

* If the number fits in 64 bits (but not 8, 16, or 32), store it in 9 bytes: a 1-byte value 255 (0xFF) followed by the 8 byte little-endian number

| Byte Index | C-Style Calculation |
|-------------|------------------------|
| 0 | 0xFF |
| 1 | value & 255 |
| 2 | (value >> 8) & 255  |
| 3 | (value >> 16) & 255  |
| 4 | (value >> 24) & 255  |
| 5 | (value >> 32) & 255  |
| 6 | (value >> 40) & 255  |
| 7 | (value >> 48) & 255  |
| 8 | (value >> 56) & 255  |
