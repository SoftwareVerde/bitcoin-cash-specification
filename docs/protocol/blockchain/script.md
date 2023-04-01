# Script

Bitcoin Cash transactions make use of a scripting language to authorize and secure transfers.
While, colloquially, there is a tendency to refer to transactions as "sending" Bitcoin Cash to "an address", that is merely an abstraction.
In fact, the only thing that permits the spending of existing [UTXOs](/protocol/blockchain/transaction#transaction-output) is the successful execution of a script.
The only thing preventing the spending of newly created UTXOs is the difficulty of producing a successfully executing script.
Through the use of cryptographic signatures and hash functions, such scripts are often designed specifically to be difficult to produce unless you are the intended spender of a given UTXO, though that need not necessarily be the case.

For more information on how Transactions are commonly secured, see [Locking Script](/protocol/blockchain/transaction/locking-script).

This page will focus on how the scripts are run, what they are capable of, and what limitations they have.

## Script Execution

Scripts are executed using a stack-based memory model and have an intentionally restricted set of available operations.
Unlike the common general-purpose programming languages your are probably aware of, Script (the term for the language itself) does not allow for loops, persistent state/memory across script executions, or the definition of functions.
Instead, scripts are expected to contain whatever data they need and use the available operations to prove transaction validity.

### Features

In addition to the primary stack ("the stack"), there is a secondary stack, referred to as the "alt-stack", which data can be moved to temporarily.
Any data left on the alt-stack is lost when a given sub-script finishes execution.
In effect, any data moved to the alt-stack by an unlocking script is not present when the locking script runs.

There are a large number of op-codes that support everything from simple stack-manipulation, to mathematical calculations, to complex cryptographic processes.  In terms of control structures there are only basic conditional branching (IF/ELSE) operations available.

### Transaction Validation

Scripts are run when validating transactions, and successful execution of all of the scripts defined by the transaction is a necessary, but not sufficient, condition for transaction validity.
See [Transaction Validation](/protocol/blockchain/transaction-validation) for more details.

As a part of validating a transaction, a script is built for each input spent by the transaction.
Each script is the sequential execution (carrying over the same stack, but not alt-stack) of the [unlocking script](/protocol/blockchain/transaction/unlocking-script) provided with the input definition (which is used that the beginning of the script) and the locking script provided by the [previous output](/protocol/blockchain/transaction#transaction-output) being referenced.
The exception to this is [pay to script hash](/protocol/blockchain/transaction/locking-script#standard-scripts), which has an altered execution workflow.
In general, though, this combined unlocking/locking script is then executed and considered successful if and only if the following conditions are met:

 - **Non-Zero Value** - after execution the top of the stack must contain a non-zero (TRUE) value.
 - **No Stack Overflows** - no operation should attempt to pop a value from the stack when the stack is empty.  An overflow of the alt-stack is also disallowed.
 - **Clean Stack** - after execution the stack must only contain a single value, which must be non-zero (TRUE).  Added in [HF-20181115](/protocol/forks/hf-20181115).  The alt-stack is exempt from this.

Additionally, in order for the combined script to be valid, the following must be true:

 - **Non-Empty Scripts** - both the locking and unlocking scripts must be non-empty.
 - **Max Script Length** - the locking and unlocking script, when executed, must each be less than the max script length of 10,000 bytes (for a combined script maximum of 20,000 bytes).
 - **Contained Control Flow** - an IF/ELSE block cannot start in the unlocking script and end in the locking script, the script must be in the top-level scope when the locking script execution begins.
 - **Permitted Operations Only** - the locking script must not include operations that are disallowed and must not execute operations that are disabled..
 - **Push Only** - the unlocking script must contain only push operations (i.e. those with op codes 0x60 or less).  Added in [HF-20181115](/protocol/forks/hf-20181115).

NOTE: violations of the above rules does not necessarily make a transaction invalid.
For example, a locking script may be longer than 10,000 bytes, but it would be unspendable, since the max script length is only checked when the scripts are combined before execution.

## Operation codes (opcodes)

The table below lists the currently allocated op codes.  Op codes marked with **(ignored)** are permitted but will do nothing when executed.
Op codes marked with **(disabled)** are permitted in scripts so long as they are not executed.
Op codes marked with **(do not use)** are disallowed and will make a transaction invalid merely be being present.

### Constants

| Word            | Value | Hex       | Input | Output | Description                                                 |
| --------------- | ----- | --------- | ----- | ------ | ----------------------------------------------------------- |
| OP_0, OP_FALSE  | 0     | 0x00      |       | 0      | An empty array of bytes is pushed onto the stack. See also [OP_X](/protocol/blockchain/script/op-codes/op-x) |
| N/A             | 1-75  | 0x01-0x4b |       |        | The next *value* bytes is data to be pushed onto the stack. See also [OP_DATA_X](/protocol/blockchain/script/op-codes/op-data-x) |
| OP_PUSHDATA1    | 76    | 0x4c      |       |        | The next byte contains the number of bytes to be pushed onto the stack.  |
| OP_PUSHDATA2    | 77    | 0x4d      |       |        | The next two bytes contain the number of bytes to be pushed onto the stack in little endian order. |
| OP_PUSHDATA4    | 78    | 0x4e      |       |        | The next four bytes contain the number of bytes to be pushed onto the stack in little endian order. |
| OP_1NEGATE      | 79    | 0x4f      |       | -1     | The number -1 is pushed onto the stack.                     |
| OP_1, OP_TRUE   | 81    | 0x51      |       | 1      | The number 1 is pushed onto the stack.                      |
| OP_2-OP_16      | 82-96 | 0x52-0x60 |       | 2-16   | The number (2-16) is pushed onto the stack.                 |

### Flow control

| Word      | Value | Hex  | Input                       | Output                       | Description                |
| --------- | ----- | ---- | --------------------------- | ---------------------------- | -------------------------- |
| OP_NOP    | 97    | 0x61 |                             |                              | Does nothing.              |
| OP_IF     | 99    | 0x63 | <expression> IF [statements] [ELSE [statements]] ENDIF    || If the top stack value is not False, the statements are executed. The top stack value is removed. |
| OP_NOTIF  | 100   | 0x64 | <expression> NOTIF [statements] [ELSE [statements]] ENDIF || If the top stack value is False, the statements are executed. The top stack value is removed. |
| OP_ELSE   | 103   | 0x67 | <expression> IF [statements] [ELSE [statements]] ENDIF    || If the preceding OP_IF or OP_NOTIF or OP_ELSE was not executed then these statements are and if the preceding OP_IF or OP_NOTIF or OP_ELSE was executed then these statements are not. |
| OP_ENDIF  | 104   | 0x68 | <expression> IF [statements] [ELSE [statements]] ENDIF    || Ends an if/else block. All blocks must end, or the transaction is **marked as invalid**. An OP_ENDIF without OP_IF earlier is also **invalid**. |
| OP_VERIFY | 105   | 0x69 | true / false                | Nothing / *fail*             | **Marks transaction as invalid** if top stack value is not true. The top stack value is removed. |
| OP_RETURN | 106   | 0x6a |                             | *fail*                       | **Marks the output as unspendable**. Since [Bitcoin Core 0.9](https://bitcoin.org/en/release/v0.9.0#opreturn-and-data-in-the-block-chain), a standard way of attaching extra data to transactions is to add a zero-value output with a scriptPubKey consisting of OP_RETURN followed by data. Such outputs are provably unspendable and specially discarded from storage in the UTXO set, reducing their cost to the network. Current [standard relay rules](https://reference.cash/protocol/blockchain/transaction-validation/network-level-validation-rules/) on the Bitcoin Cash network allow a single output with OP_RETURN, that contains any sequence of push statements (or OP_RESERVED) after the OP_RETURN provided the total scriptPubKey length is at most 223 bytes. |

### Stack

| Word            | Value | Hex  | Input               | Output                 | Description                           |
| --------------- | ----- | ---- | ------------------- | ---------------------- | ------------------------------------- |
| OP_TOALTSTACK   | 107   | 0x6b | x1                  | (alt) x1               | Puts the input onto the top of the alt stack. Removes it from the main stack. |
| OP_FROMALTSTACK | 108   | 0x6c | (alt) x1            | x1                     | Puts the input onto the top of the main stack. Removes it from the alt stack. |
| OP_IFDUP        | 115   | 0x73 | x                   | x / x x                | If the top stack value is not 0, duplicate it. |
| OP_DEPTH        | 116   | 0x74 | Nothing             | &lt;stack size&gt;           | Puts the number of stack items onto the stack. |
| OP_DROP         | 117   | 0x75 | x                   | Nothing                | Removes the top stack item.           |
| OP_DUP          | 118   | 0x76 | x                   | x x                    | Duplicates the top stack item.        |
| OP_NIP          | 119   | 0x77 | x1 x2               | x2                     | Removes the second-to-top stack item. |
| OP_OVER         | 120   | 0x78 | x1 x2               | x1 x2 x1               | Copies the second-to-top stack item to the top. |
| OP_PICK         | 121   | 0x79 | xn ... x2 x1 x0 n | xn ... x2 x1 x0 xn     | The item *n* back in the stack is copied to the top. |
| OP_ROLL         | 122   | 0x7a | xn ... x2 x1 x0 n | x(n-1) ... x2 x1 x0 xn | The item *n* back in the stack is moved to the top. |
| OP_ROT          | 123   | 0x7b | x1 x2 x3	           | x2 x3 x1	              | The top three items on the stack are rotated to the left. |
| OP_SWAP         | 124   | 0x7c | x1 x2	              | x2 x1                  | The top two items on the stack are swapped. |
| OP_TUCK         | 125   | 0x7d | x1 x2	              | x2 x1 x2	              | The item at the top of the stack is copied and inserted below the second-to-top item. |
| OP_2DROP        | 109   | 0x6d | x1 x2	              | Nothing                | Removes the top two stack items.      |
| OP_2DUP         | 110   | 0x6e | x1 x2             	 | x1 x2 x1 x2	           | Duplicates the top two stack items.   |
| OP_3DUP         | 111   | 0x6f | x1 x2 x3	           | x1 x2 x3	x1 x2 x3     	| Duplicates the top three stack items. |
| OP_2OVER        | 112   | 0x70 | x1 x2 x3 x4	        |  x1 x2 x3 x4	x1 x2     | Copies the pair of items two spaces back in the stack to the front. |
| OP_2ROT         | 113   | 0x71 | x1 x2 x3 x4 x5 x6	  | x3 x4 x5 x6 x1 x2	     | The fifth and sixth items back are moved to the top of the stack. |
| OP_2SWAP        | 114   | 0x72 | x1 x2 x3 x4	        | x3 x4 x1 x2          	 | Swaps the top two pairs of items.     |

### Splice

|Word       |Value  |Hex |Input         |Output  | Description                                                      |
|-----------|-------|----|--------------|--------|------------------------------------------------------------------|
|OP_CAT     |126    |0x7e|x1 x2         |out     |Concatenates two byte sequences                                   |
|OP_SPLIT   |127    |0x7f|x n           |x1 x2   |Splits byte sequence *x* at position *n*. Known as OP_SUBSTR before 2018-05-15. |
|OP_NUM2BIN |128    |0x80|a b           |out     |Converts numeric value *a* into byte sequence of length *b*. Known as OP_LEFT before 2018-05-15.       |
|OP_BIN2NUM |129    |0x81|x             |out     |Converts byte sequence *x* into a numeric value. Known as OP_RIGHT before 2018-05-15. |
|OP_SIZE    |130    |0x82|x          |x size     |Pushes the string length of the top element of the stack (without popping it). |
|OP_REVERSEBYTES |188 |0xbc |x |out     |Reverses the order of the bytes in byte sequence *x* so that the first byte is now its last byte, the second is now its second-to-last, and so forth. Enabled in [HF-20200515](/protocol/forks/hf-20200515). |

### Bitwise logic

|Word       |Value  |Hex |Input         |Output  | Description                                                      |
|-----------|-------|----|--------------|--------|------------------------------------------------------------------|
|OP_INVERT      |131    |0x83|N/A           |N/A              | **DISABLED**                                           |
|OP_AND         |132    |0x84|x1 x2         |out              |Boolean *AND* between each bit of the inputs            |
|OP_OR          |133    |0x85|x1 x2         |out              |Boolean *OR* between each bit of the inputs.            |
|OP_XOR         |134    |0x86|x1 x2         |out              |Boolean *EXCLUSIVE OR* between each bit of the inputs.  |
|OP_EQUAL       |135    |0x87|x1 x2         |true / false     |Returns 1 if the inputs are exactly equal, 0 otherwise. |
|OP_EQUALVERIFY |136    |0x88|x1 x2         |Nothing / *fail* |Same as OP_EQUAL, but runs OP_VERIFY afterward.         |

### Arithmetic

Numeric opcodes (OP_1ADD, etc) are restricted to operating on 4-byte integers. The semantics are subtle, though: operands must be in the range [-2^31 +1...2^31 -1], but results may overflow (and are valid as long as they are not used in a subsequent numeric operation).

|Word                 |Value  |Hex |Input         |Output           | Description                                          |
|---------------------|-------|----|--------------|-----------------|------------------------------------------------------|
|OP_1ADD              | 139   |0x8b|in            |out              | 	1 is added to the input.                            |
|OP_1SUB              | 140   |0x8c|in            |out              |  1 is subtracted from the input.                     |
|OP_2MUL              | 141   |0x8d|in            |out              | The input is multiplied by 2. **DISABLED**           |
|OP_2DIV              | 142   |0x8e|in            |out              | The input is divided by 2. **DISABLED**              |
|OP_NEGATE            | 143   |0x8f|in            |out              | The sign of the input is flipped.                    |
|OP_ABS               | 144   |0x90|in            |out              | The input is made positive.                          |
|OP_NOT               | 145   |0x91|in            |true / false     | If the input is 0 or 1, it is flipped. Otherwise the output will be 0. |
|OP_0NOTEQUAL         | 146   |0x92|in            |true / false    	| Returns 0 if the input is 0. 1 otherwise.            |
|OP_ADD               | 147   |0x93|a b           |out              | *a* is added to *b*.                                 |
|OP_SUB               | 148   |0x94|a b           |out              | *b* is subtracted from *a*.                          |
|OP_MUL               | 149   |0x95|a b           |out              | *a* is multiplied by *b*.  **DISABLED**              |
|OP_DIV               | 150   |0x96|a b           |out              | *a* is [divided](/protocol/blockchain/script/integer-division) by *b*.                               |
|OP_MOD               | 151   |0x97|a b           |out              | Returns the remainder after *a* is [divided](/protocol/blockchain/script/integer-division) by *b*.   |
|OP_LSHIFT            | 152   |0x98|a b           |out              | Shifts *a* left *b* bits, preserving sign. **DISABLED** |
|OP_RSHIFT            | 153   |0x99|a b           |out              | Shifts *a* right *b* bits, preserving sign. **DISABLED** |
|OP_BOOLAND           | 154   |0x9a|a b           |true / false     | If both *a* and *b* are not 0, the output is 1. Otherwise 0. |
|OP_BOOLOR            | 155   |0x9b|a b           |true / false     | If *a* or *b* is not 0, the output is 1. Otherwise 0.|
|OP_NUMEQUAL          | 156   |0x9c|a b           |true / false     | Returns 1 if the numbers are equal, 0 otherwise.     |
|OP_NUMEQUALVERIFY    | 157   |0x9d|a b           |Nothing / *fail* | Same as OP_NUMEQUAL, but runs OP_VERIFY afterward.   |
|OP_NUMNOTEQUAL       | 158   |0x9e|a b           |true / false     | Returns 1 if the numbers are not equal, 0 otherwise. |
|OP_LESSTHAN          | 159   |0x9f|a b           |true / false     | Returns 1 if *a* is less than *b*, 0 otherwise.      |
|OP_GREATERTHAN       | 160   |0xa0|a b           |true / false     | Returns 1 if *a* is greater than *b*, 0 otherwise.   |
|OP_LESSTHANOREQUAL   | 161   |0xa1|a b           |true / false     | Returns 1 if *a* is less than or equal to *b*, 0 otherwise. |
|OP_GREATERTHANOREQUAL| 162   |0xa2|a b           |true / false     | Returns 1 if *a* is greater than or equal to *b*, 0 otherwise. |
|OP_MIN               | 163   |0xa3|a b           |out              | Returns the smaller of a and b.                      |
|OP_MAX               | 164   |0xa4|a b           |out              | Returns the larger of a and b.                       |
|OP_WITHIN            | 165   |0xa5|x min max     |true / false     | Returns 1 if *x* is within the specified range (left-inclusive), 0 otherwise. |

### Cryptography

|Word                    |Value | Hex  |Input           |Output   | Description                                   |
|------------------------|------|------|----------------|---------|--------------------------------------------------------|
| OP_RIPEMD160           | 166  | 0xa6 | in             | hash    | Hashes input with RIPEMD-160. |
| OP_SHA1                | 167  | 0xa7 | in             | hash    | Hashes input with SHA-1. |
| OP_SHA256              | 168  | 0xa8 | in             | hash    | Hashes input with SHA-256. |
| OP_HASH160             | 169  | 0xa9 | in             | hash    | Hashes input with SHA-256 and then with RIPEMD-160. |
| OP_HASH256             | 170  | 0xaa | in             | hash    | Hashes input twice with SHA-256. |
| OP_CODESEPARATOR	      | 171  | 0xab | Nothing        | Nothing | Makes `OP_CHECK(MULTI)SIG(VERIFY)` use the subset of the script of everything after the most recently-executed OP_CODESEPARATOR when computing the sighash. | 
| OP_CHECKSIG	           | 172  | 0xac | sig pubkey	    | true / false     | The last byte (=sighash type) of the signature is removed. The sighash for this input is calculated based on the sighash type. The truncated signature used by OP_CHECKSIG must be a valid ECDSA or Schnorr signature for this hash and public key. If it is valid, 1 is returned, if it is empty, 0 is returned, otherwise the operation fails. |
| OP_CHECKSIGVERIFY      | 173  | 0xad | sig pubkey	    | Nothing / *fail* | Same as OP_CHECKSIG, but OP_VERIFY is executed afterward. |
| OP_CHECKMULTISIG	      | 174  | 0xae | dummy sig1 sig2 ... &lt;#-of-sigs&gt; pub1 pub2 ... &lt;#-of-pubkeys&gt; | true / false | Signatures are checked against public keys. Signatures must be placed in the unlocking script using the same order as their corresponding public keys were placed in the locking script or redeem script. If all signatures are valid, 1 is returned, 0 otherwise. All elements are removed from the stack. For more information on the execution of this opcode, see [Multisignature](/protocol/blockchain/cryptography/multisignature). |
| OP_CHECKMULTISIGVERIFY | 175  | 0xaf | dummy sig1 sig2 ... &lt;#-of-sigs&gt; pub1 pub2 ... &lt;#-of-pubkeys&gt; | Nothing / *fail*  | Same as OP_CHECKMULTISIG, but OP_VERIFY is executed afterward. |
| OP_CHECKDATASIG        | 186  | 0xba | sig msg pubkey | true / false | Check if signature is valid for message and a public key. [See spec](/protocol/forks/op_checkdatasig) |
| OP_CHECKDATASIGVERIFY | 187  | 0xbb | sig msg pubkey | nothing / *fail* | Same as OP_CHECKDATASIG, but runs OP_VERIFY afterward. |

### Locktime

| Word                   | Value   | Hex       | Input |Output     | Description                                     |
| ---------------------- | ------- | --------- | ----- | --------- | ----------------------------------------------- |
| OP_CHECKLOCKTIMEVERIFY | 177     | 0xb1      | x     |x / *fail* | Marks transaction as invalid if the top stack item is greater than the transaction's nLockTime field, otherwise script evaluation continues as though an OP_NOP was executed. Transaction is also invalid if 1. the stack is empty; or 2. the top stack item is negative; or 3. the top stack item is greater than or equal to 500000000 while the transaction's nLockTime field is less than 500000000, or vice versa; or 4. the input's nSequence field is equal to 0xffffffff. The precise semantics are described in [BIP65](/protocol/forks/bip-0065). |
| OP_CHECKSEQUENCEVERIFY | 178     | 0xb2      | x     |x / *fail* |  Marks transaction as invalid if the relative lock time of the input (enforced by BIP68 with nSequence) is not equal to or longer than the value of the top stack item. The precise semantics are described in [BIP112](/protocol/forks/bip-0112). |

### Introspection

|Word                    |Value | Hex  |Input           |Output   | Description                                            |
|------------------------|------|------|----------------|---------|--------------------------------------------------------|
| OP_INPUTINDEX          | 192  | 0xc0 | Nothing        | number  | Push the index of the input being evaluated to the stack as a Script Number.   |
| OP_ACTIVEBYTECODE      | 193  | 0xc1 | Nothing        | script  | Push the bytecode currently being evaluated, beginning after the last executed OP_CODESEPARATOR, to the stack1. For Pay-to-Script-Hash (P2SH) evaluations, this is the redeem bytecode of the Unspent Transaction Output (UTXO) being spent; for all other evaluations, this is the locking bytecode of the UTXO being spent.  |
| OP_TXVERSION           | 194  | 0xc2 | Nothing        | number  | Push the version of the current transaction to the stack as a Script Number. |
| OP_TXINPUTCOUNT        | 195  | 0xc3 | Nothing        | number  | Push the count of inputs in the current transaction to the stack as a Script Number. |
| OP_TXOUTPUTCOUNT       | 196  | 0xc4 | Nothing        | number  | Push the count of outputs in the current transaction to the stack as a Script Number.  |
| OP_TXLOCKTIME          | 197  | 0xc5 | Nothing        | number  | Push the locktime of the current transaction to the stack as a Script Number. |
| OP_UTXOVALUE           | 198  | 0xc6 | index          | number  | Pop the top item from the stack as an input index (Script Number). Push the value (in satoshis) of the Unspent Transaction Output (UTXO) spent by that input to the stack as a Script Number. |
| OP_UTXOBYTECODE        | 199  | 0xc7 | index          | script  | Pop the top item from the stack as an input index (Script Number). Push the full locking bytecode of the Unspent Transaction Output (UTXO) spent by that input to the stack. |
| OP_OUTPOINTTXHASH      | 200  | 0xc8 | index          | hash    | Pop the top item from the stack as an input index (Script Number). From that input, push the outpoint transaction hash – the hash of the transaction which created the Unspent Transaction Output (UTXO) which is being spent – to the stack in OP_HASH256 byte order. |
| OP_OUTPOINTINDEX       | 201  | 0xc9 | index          | number  | Pop the top item from the stack as an input index (Script Number). From that input, push the outpoint index – the index of the output in the transaction which created the Unspent Transaction Output (UTXO) which is being spent – to the stack as a Script Number.                                                       |
| OP_INPUTBYTECODE       | 202  | 0xca | index          | script  | Pop the top item from the stack as an input index (Script Number). Push the unlocking bytecode of the input at that index to the stack. |
| OP_INPUTSEQUENCENUMBER | 203  | 0xcb | index          | number  | Pop the top item from the stack as an input index (Script Number). Push the sequence number of the input at that index to the stack as a Script Number. |
| OP_OUTPUTVALUE         | 204  | 0xcc | index          | number  | Pop the top item from the stack as an output index (Script Number). Push the value (in satoshis) of the output at that index to the stack as a Script Number. |
| OP_OUTPUTBYTECODE      | 205  | 0xcd | index          | script  | Pop the top item from the stack as an output index (Script Number). Push the locking bytecode of the output at that index to the stack. |

### Reserved

| Word             | Value   | Hex       | Description                                                              |
| ---------------- | ------- | --------- | ------------------------------------------------------------------------ |
| OP_NOP1          | 176     | 0xb0      | Previously reserved for OP_EVAL (BIP12).                                 |
| OP_NOP4-OP_NOP10 | 179-185 | 0b3-0xb9  | Ignored. Does not mark transaction as invalid.                           |

### Uncategorized

Please help improve this article by categorizing and describing the following op codes.

| Hex  | Word |
| ---- | ---- |
| 0x50 | OP_RESERVED **(disabled)** |
| 0x62 | OP_VER **(disabled)** |
| 0x65 | OP_VERIF **(do not use)** |
| 0x66 | OP_VERNOTIF **(do not use)** |
| 0x89 | OP_RESERVED1 **(do not use)** |
| 0x8A | OP_RESERVED2 **(do not use)** |
| 0xBD - 0xFF | Unused **(disabled)** |
