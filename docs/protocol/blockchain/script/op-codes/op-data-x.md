# OP_DATA_X

The `OP_DATA_X` op codes push bytes following the opcode from the script to the top of the stack.  The number of bytes pushed by the op code is the value of the op code interpreted as a [two's complement](//en.wikipedia.org/wiki/Two%27s_complement) integer.  For example, `OP_DATA_4` (op code `0x04`) pushes the next `4` bytes in the script as a single value on the stack.

| Script | Post-Execution Stack |
| -- | -- |
| 0x04 0xFFFF001D | |
| ~~0x04~~ ~~0xFFFF001D~~ | 0xFFFF001D |
