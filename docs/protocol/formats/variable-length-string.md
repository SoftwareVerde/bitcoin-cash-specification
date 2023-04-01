# Variable Length String

A variable-width data format for ASCII character strings.

## Format

| Field | Length | Format | Description |
|--|--|--|--|
| character count | variable | [variable length integer](/protocol/formats/variable-length-integer) | The number of ASCII characters (bytes) to follow. |
| character string | `character_count` bytes | ASCII Characters | The string of characters. |
