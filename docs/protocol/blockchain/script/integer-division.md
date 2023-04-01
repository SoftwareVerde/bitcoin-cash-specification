# Script Integer Division

The Bitcoin Script [OP_DIV](/protocol/blockchain/script#arithmetic) and [OP_MOD](/protocol/blockchain/script#arithmetic) operations are performed on script numbers, which are signed integers.
However, there are multiple valid approaches to signed integer division, particularly with respect to how negative values are handled, so this must be disambiguated.

The above operations follow [C](https://en.wikipedia.org/wiki/C_(programming_language))-style integer division semantics.
For a given `numerator` and `denominator`, if `OP_DIV` returns `quotient` and `OP_MOD` returns `remainder`, the following relation be true: `numerator = quotient * denominator + remainder`.
This allows for both negative quotients and remainders.

The following examples may provide clarity:

    OP_DIV  5  2   ->   2
    OP_MOD  5  2   ->   1
    OP_DIV -5  2   ->  -2
    OP_MOD -5  2   ->  -1
    OP_DIV  5 -2   ->  -2
    OP_MOD  5 -2   ->   1
    OP DIV -5 -2   ->   2
    OP_MOD -5 -2   ->  -1
