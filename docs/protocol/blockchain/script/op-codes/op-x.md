# OP_X

The `OP_X` op codes add a numerical value to the top of the stack.
`OP_0` pushes an empty byte array which is interpreted as the numerical value `0`.
The rest push a single byte to the top of the stack as a [two's complement](//en.wikipedia.org/wiki/Two%27s_complement) integer.
`OP_1` pushes a `1`, `OP_2` pushes a `2`, and so on through `OP_16`, which adds a `16` (`0x10`).

# OP_TRUE and OP_FALSE

`OP_FALSE` is an alias for `OP_0` while `OP_TRUE` is an alias for `OP_1`.