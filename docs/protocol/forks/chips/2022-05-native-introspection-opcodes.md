# CHIP-2021-02: Native Introspection Opcodes

> OWNERS: [Jason Dreyzehner](https://bitjson.com/), [Jonathan Silverblood](https://gitlab.com/monsterbitar)
>
> DISCUSSION: [Bitcoin Cash Research](https://bitcoincashresearch.org/t/native-introspection-chip-discussion/307), [Telegram](https://t.me/transactionintrospection)
>
> VERSION: 1.1.4
>
> MILESTONES: **[Published](https://gitlab.com/GeneralProtocols/research/-/blob/master/CHIPs/May%202022,%20Native%20Introspection.md)**, **[Specification](#technical-specification)**, **[Testnet](https://read.cash/@bitcoincashnode/bch-testnet4-for-may-2022-network-upgrade-updated-2021-11-23-95a21d51)**, **Accepted ([BU](https://twitter.com/BitcoinUnlimit/status/1460394221240786956) - [BCHN](https://twitter.com/bitcoincashnode/status/1460424339816284161) - [Knuth](https://twitter.com/KnuthNode/status/1460622308607938579) - [Verde](https://twitter.com/joshmgreen/status/1460592944516317185) - [Bitauth](https://twitter.com/Bitauth/status/1460371045207232512))**, Deployed (May 15th, 2022).

## Summary

This proposal adds a set of new virtual machine (VM) operations which enable BCH contracts to efficiently access details about the current transaction like output values, recipients, and more – without increasing transaction validation costs.

## Deployment

Deployment of this specification is proposed for the May 2022 upgrade.

This proposal does not depend on [`CHIP: Bigger Script Integers`](./CHIP-2021-02-Bigger-Script-Integers.md), but support for larger script numbers is required for all possible results of `OP_UTXOVALUE` and `OP_OUTPUTVALUE` to be used in arithmetic operations. It is therefore recommended that both CHIPs be deployed together.

This proposal does not depend on [`CHIP: Version 3 Transaction Format (PMv3)`](https://github.com/bitjson/pmv3), but it includes an [integration specification](#chip-integration-version-3-transaction-format-pmv3) to add introspection support for the v3 transaction format. See also: [Interaction with PMv3](#interaction-with-pmv3).

## Motivation

Since the introduction of OP_CHECKDATASIG (2018-11-15), it has been possible to implement practical Bitcoin Cash **covenants – contracts which validate properties of the transaction in which the contract funds are spent**.

Covenants enable a wide range of new innovation, but the strategy by which they are currently implemented is extremely inefficient: most of a transactions contents must be duplicated for each input which utilizes a covenant. In practice, this doubles or triples the size of even the simplest covenant transactions<sup>1</sup>, and advanced covenant applications quickly exceed VM limits such as the maximum standard unlocking bytecode length (A.K.A. `MAX_TX_IN_SCRIPT_SIG_SIZE`) of 1,650 bytes. This severely limits the extent of current BCH covenant development and usage.

> Covenants are currently implemented using a workaround in which the same signature is checked by both `OP_CHECKSIG` and `OP_CHECKDATASIG`. The `OP_CHECKSIG` confirms the signature is valid for the current transaction, and the `OP_CHECKDATASIG` allows the contract to validate that the signature covers a particular preimage provided in the unlocking bytecode. If both checks are successful, the contract can trust that the preimage provided to `OP_CHECKDATASIG` is the genuine signing serialization of the current transaction. By further inspecting this preimage, the contract can validate other properties of the transaction.

Because nodes are already required to have full access to a transaction's contents and UTXO information during transaction validation, native introspection opcodes can be introduced without impacting existing transaction validation costs.

<details>
<summary><b>Calculations</b></summary>

1. An optimized implementation of the `OP_CHECKSIG` + `OP_CHECKDATASIG` workaround (`<public_key> <signature> <preimage> OP_3DUP OP_SHA256 OP_ROT OP_CHECKDATASIGVERIFY OP_DROP <sighash_flags> OP_CAT OP_SWAP OP_CHECKSIGVERIFY`) requires at least 12 bytes of operations, a 33-byte public key, a 65 to 73-byte signature, and a [signing serialization preimage which is typically at least 188 bytes](https://github.com/bitcoincashorg/bitcoincash.org/blob/3e2e6da8c38dab7ba12149d327bc4b259aaad684/spec/replay-protected-sighash.md#digest-algorithm). In total, this construction is expected to require at least 298 bytes per covenant input. For some contracts, the preimage can be partially generated using `SIGHASH_ANYONECANPAY` and `OP_NUM2BIN`, theoretically reducing the preimage size to ~90 bytes and bringing the minimum possible overhead to ~200 bytes.

</details>

## Benefits

Adding native support for introspection operations would make covenants simpler, safer, and more efficient, enabling innovative new use cases.

### Simpler, Safer Contracts

While contracts using the current covenant workaround must carefully validate all provided transaction information, contracts using native introspection operations could safely rely on information returned by the VM without further validation. This significantly reduces contract size and complexity, making contract development and security review easier.

### Reduced Transaction Sizes

By eliminating the need for a wasteful double-signature checking workaround, covenant transaction sizes can be reduced by hundreds of bytes, making them as efficient as other common transaction types. This would reduce wasted network bandwidth and lower transaction fees for all covenant applications.

Because covenant applications cover a large variety of common transaction types – including scheduled and recurring payments – improved efficiency in covenant transactions would significantly improve overall throughput of the BCH network.

### Enable Innovation

By eliminating waste in covenant contracts, native introspection operations can extend the scope of possible applications which can be developed within current VM limits. This would enable far more innovation on Bitcoin Cash, without increasing node validation costs.

## Costs & Risk Mitigation

The following costs and risks have been assessed.

### Node Upgrade Costs

This proposal affects consensus – all fully-validating node software must implement these VM changes to remain in consensus.

> These VM changes are backwards-compatible: all past and currently-possible transactions remain valid under these new rules.

### Other Software Upgrade Costs

While most wallets, indexers, and other software will not require updates to support this proposal (beyond upgrades to any supporting node infrastructure), updates will be required to some libraries, transaction compilers, and other software which implements the BCH VM (e.g. [Bitauth IDE](https://github.com/bitauth/bitauth-ide)).

### Assignment of Opcodes

The specified operations would occupy 15 codepoints within the BCH VM instruction set. This represents a notable portion of the remaining 81 unused codepoints (80, 98, 101, 102, 137, 138, 176, 179-185, 189-255). However, we consider this to be a [prudent use of these codepoints](#use-of-single-byte-opcodes).

## Technical Specification

A range of Bitcoin Cash VM codepoints is reserved for transaction introspection operations – `0xc0` (192) through `0xcf` (207) – and a new set of 15 operations allows contracts to introspect all available transaction and evaluation state.

### Nullary Operations

The following 6 operations consume no items and push a single result to the stack. If the item to be pushed to the stack is longer than the stack item length limit (A.K.A. `MAX_SCRIPT_ELEMENT_SIZE`), immediately fail evaluation. If the additional stack item would cause the stack to exceed the maximum stack size (A.K.A. `MAX_STACK_SIZE`), immediately fail evaluation.

| Operation         | Codepoint         | Description                                                                                                                                                                                                                                                                                                                                            |
| ----------------- | ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| OP_INPUTINDEX     | `0xc0`&nbsp;(192) | Push the index of the input being evaluated to the stack as a Script Number.                                                                                                                                                                                                                                                                           |
| OP_ACTIVEBYTECODE | `0xc1`&nbsp;(193) | Push the bytecode currently being evaluated, beginning after the last executed `OP_CODESEPARATOR`, to the stack<sup>1</sup>. For Pay-to-Script-Hash (P2SH) evaluations, this is the redeem bytecode of the Unspent Transaction Output (UTXO) being spent; for all other evaluations, this is the locking bytecode of the UTXO being spent.<sup>2</sup> |
| OP_TXVERSION      | `0xc2`&nbsp;(194) | Push the version of the current transaction to the stack as a Script Number.                                                                                                                                                                                                                                                                           |
| OP_TXINPUTCOUNT   | `0xc3`&nbsp;(195) | Push the count of inputs in the current transaction to the stack as a Script Number.                                                                                                                                                                                                                                                                   |
| OP_TXOUTPUTCOUNT  | `0xc4`&nbsp;(196) | Push the count of outputs in the current transaction to the stack as a Script Number.                                                                                                                                                                                                                                                                  |
| OP_TXLOCKTIME     | `0xc5`&nbsp;(197) | Push the locktime of the current transaction to the stack as a Script Number.                                                                                                                                                                                                                                                                          |

1. `OP_ACTIVEBYTECODE` pushes the serialized bytecode for the instructions currently under evaluation beginning after the most recently executed `OP_CODESEPARATOR` and continuing through the final instruction. If no `OP_CODESEPARATOR` has been executed, `OP_ACTIVEBYTECODE` pushes the full, serialized bytecode for the instructions currently under evaluation. (In the Satoshi implementation, this is simply the `CScript` contents passed to the current `EvalScript`.)
2. This behavior matches the existing behavior of the BCH VM during P2SH evaluation – once the P2SH pattern is matched, the remaining stack is copied, and the VM begins evaluation again with the P2SH redeem bytecode set as the new `active bytecode`. (In the Satoshi implementation, this P2SH redeem bytecode is passed as a `CScript` to a new execution of `EvalScript`.)

### Unary Operations

The following 9 operations pop the top item from the stack as an index (Script Number) and push a single result to the stack. If the consumed value is not a valid, minimally-encoded index for the operation, an error is produced. If the item to be pushed to the stack is longer than the stack item length limit (A.K.A. `MAX_SCRIPT_ELEMENT_SIZE`), immediately fail evaluation.

| Operation              | Codepoint         | Description                                                                                                                                                                                                                                                                          |
| ---------------------- | ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| OP_UTXOVALUE           | `0xc6`&nbsp;(198) | Pop the top item from the stack as an input index (Script Number). Push the value (in satoshis) of the Unspent Transaction Output (UTXO) spent by that input to the stack as a Script Number.                                                                                        |
| OP_UTXOBYTECODE        | `0xc7`&nbsp;(199) | Pop the top item from the stack as an input index (Script Number). Push the full locking bytecode of the Unspent Transaction Output (UTXO) spent by that input to the stack.                                                                                                         |
| OP_OUTPOINTTXHASH      | `0xc8`&nbsp;(200) | Pop the top item from the stack as an input index (Script Number). From that input, push the outpoint transaction hash – the hash of the transaction which created the Unspent Transaction Output (UTXO) which is being spent – to the stack in `OP_HASH256` byte order<sup>1</sup>. |
| OP_OUTPOINTINDEX       | `0xc9`&nbsp;(201) | Pop the top item from the stack as an input index (Script Number). From that input, push the outpoint index – the index of the output in the transaction which created the Unspent Transaction Output (UTXO) which is being spent – to the stack as a Script Number.                 |
| OP_INPUTBYTECODE       | `0xca`&nbsp;(202) | Pop the top item from the stack as an input index (Script Number). Push the unlocking bytecode of the input at that index to the stack.                                                                                                                                              |
| OP_INPUTSEQUENCENUMBER | `0xcb`&nbsp;(203) | Pop the top item from the stack as an input index (Script Number). Push the sequence number of the input at that index to the stack as a Script Number.                                                                                                                              |
| OP_OUTPUTVALUE         | `0xcc`&nbsp;(204) | Pop the top item from the stack as an output index (Script Number). Push the value (in satoshis) of the output at that index to the stack as a Script Number.                                                                                                                        |
| OP_OUTPUTBYTECODE      | `0xcd`&nbsp;(205) | Pop the top item from the stack as an output index (Script Number). Push the locking bytecode of the output at that index to the stack.                                                                                                                                              |

1. This is the byte order produced/required by all BCH VM operations which employ SHA-256 (including `OP_SHA256` and `OP_HASH256`), the byte order used for outpoint transaction hashes in the P2P transaction format, and the byte order produced by most SHA-256 libraries. For reference, the genesis block header in this byte order is little-endian – `6fe28c0ab6f1b372c1a6a246ae63f74f931e8365e15a089c68d6190000000000` – and can be produced by this script: `<0x0100000000000000000000000000000000000000000000000000000000000000000000003ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4a29ab5f49ffff001d1dac2b7c> OP_HASH256`. (Note, this is the opposite byte order as is commonly used in user interfaces like block explorers.)

---

### CHIP Integration: Bigger Script Integers

Because VM arithmetic operations currently limit `Script Number` inputs to signed 32-bit integers, the maximum results of `OP_UTXOVALUE` and `OP_OUTPUTVALUE` which can be used in practical contracts is `2147483647` satoshis (`~21.47` BCH). For this reason, **it is recommended that [`CHIP: Bigger Script Integers`](./CHIP-2021-02-Bigger-Script-Integers.md) be deployed before or with this CHIP**.

This CHIP can be deployed without `CHIP: Bigger Script Integers`, and no direct integration is required between the two CHIPs. If `CHIP: Bigger Script Integers` is not deployed with or before this proposal, the above specified operations must still behave as specified. (`OP_UTXOVALUE` and `OP_OUTPUTVALUE` may push Script Numbers to the stack which are up to 8 bytes in length and therefore could not be used as inputs to arithmetic operations. Until some arithmetic range upgrade, these operations would likely only be used in practice for values which can be encoded in 4 bytes or less.)

### CHIP Integration: Version 3 Transaction Format (PMv3)

If this proposal is adopted with or after [`CHIP: Version 3 Transaction Format (PMv3)`](https://github.com/bitjson/pmv3), the `OP_INPUTDETACHED` [unary introspection operation](#unary-operations) must also be activated:

| Operation                    | Codepoint         | Description                                                                                                                                                                        |
| ---------------------------- | ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| OP_INPUTDETACHED<sup>3</sup> | `0xce`&nbsp;(206) | Pop the top item from the stack as an input index (Script Number). If the input at that index uses a detached proof, push `1` (`0x01`), otherwise push `0` (`0x`, the empty item). |

> See [Interaction with PMv3](#interaction-with-pmv3) for rationale.

Additionally, the description of `OP_INPUTBYTECODE` can be clarified to confirm that its result is always the input's unlocking bytecode (regardless of whether or not the proof is detached):

| Operation        | Codepoint         | Description                                                                                                                                                                                                                                                      |
| ---------------- | ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| OP_INPUTBYTECODE | `0xca`&nbsp;(202) | Pop the top item from the stack as an input index (Script Number). Push the unlocking bytecode of the input at that index to the stack. (If the selected input uses a detached proof, the pushed value is the unlocking bytecode content of the detached proof.) |

## Rationale

This section documents design decisions made in this specification.

### Ordering Operations by Arity

This proposal groups new introspection operations by [arity](https://en.wikipedia.org/wiki/Arity): all operations which consume no stack values precede all operations which consume an index value from the stack.

This simplifies some implementations, allowing operations of like arities to more easily reuse logic. For example, in the Satoshi implementation, all unary numeric operations are [handled in the same fallthrough switch case](https://github.com/bitcoin-cash-node/bitcoin-cash-node/blob/8d6a597bb4d12824b2eb9a8a42708979a5395099/src/script/interpreter.cpp#L716-L727), allowing each operation to reuse the same stack pop and error handling logic.

Beyond arity, operations are arranged within the instruction set to match the order in which their results appear within the P2P transaction format.

### Operation Set Completeness

The operations specified in this proposal expose the most raw form of every static property of transaction and evaluation state within the current VM model.

This strategy necessarily incorporates operations which may initially seem to duplicate existing functionality, notably `OP_TXLOCKTIME` and `OP_INPUTSEQUENCENUMBER` (many use cases for these operations can also be accomplished using the existing `OP_CHECKLOCKTIMEVERIFY` and `OP_CHECKSEQUENCEVERIFY`, respectively). However, contract authors are not always able to reverse the order of a construction to make use of these operations. This limitation is particularly acute in covenant use cases: where other limitations prevent a contract from inverting a construction (or even providing the expected result of that operation via unlocking bytecode), some use cases are likely impossible without these functionally-similar introspection operations.

> Notably, the existing instruction set includes `OP_SUB` even though `OP_ADD` can be indirectly used (backwards) to accomplish many of the same validations. The existence of inverse and functionally-similar operations is important for both accommodating new use cases and optimizing contracts.

By implementing introspection in a single deployment as a complete, logical set of operations – rather than by piecemeal activation as contract authors lobby for operations which are important for their use cases – we allow new innovation to take place primarily in "userspace" and limit future technical debt.

> Note: introspection of dynamic VM state – e.g. current instruction pointer index, the current state of various cumulative limits, etc. – is intentionally excluded from this specification.
>
> This approach avoids consensus standardization of various implementation details which could complicate some implementations and requires further research and justification. Instead, this proposal incorporates only introspection operations for previously consensus-standardized, static properties of transaction and evaluation state which are already available to contracts via the `OP_CHECKSIG` + `OP_CHECKDATASIG` hack.

### Differences Between `OP_ACTIVEBYTECODE` and `OP_INPUTINDEX OP_UTXOBYTECODE`

The operations specified in this proposal include partially-overlapping functionality in one rare case: the results of `OP_ACTIVEBYTECODE` and `OP_INPUTINDEX OP_UTXOBYTECODE` are equal in non-P2SH contracts (i.e. spending the output of a non-standard transaction). However, in the more common (standard) P2SH case, `OP_ACTIVEBYTECODE` produces the raw redeem bytecode, while `OP_INPUTINDEX OP_UTXOBYTECODE` will produce only the already-hashed result in the P2SH-template locking bytecode (`OP_HASH160 OP_PUSHBYTES_20 <redeem_bytecode_hash> OP_EQUAL`). This distinction is very important in covenant applications: even in simple cases, it can save many hundreds of bytes by avoiding the need to push a duplicate copy of the covenant's redeem bytecode (to construct the covenant's next output). While `OP_ACTIVEBYTECODE` is very cheap for the VM (typically a simple buffer copy), this single optimization reduces many covenant sizes by 50% or more.

> To demonstrate, the following script produces a `1` for P2SH contracts, but a `0` for non-P2SH contracts (spending a non-standard transaction): `<OP_HASH160 OP_PUSHBYTES_20> OP_ACTIVEBYTECODE OP_HASH160 <OP_EQUAL> OP_CAT OP_CAT OP_INPUTINDEX OP_UTXOBYTECODE OP_EQUAL`.

Alternatively, this same functionality could be provided by modifying `OP_UTXOBYTECODE` to only return the "active" bytecode of each UTXO (i.e. for P2SH contracts, only the raw redeem bytecode), but this would require a significantly more complex implementation: a transaction's inputs would need to be evaluated in two phases, caching each P2SH input's redeem bytecode for access by other inputs where needed. Additionally, information would still be lost unless another introspection operation were made available for contracts to judge which inputs spend a P2SH UTXO (e.g. a unary `OP_ISP2SH`).

An advantage of that more complex solution over the proposed `OP_ACTIVEBYTECODE` solution could be more efficient access to the raw redeem bytecode of sibling inputs (other than the "active" one). While this might be useful in optimizing some highly-advanced covenants, the proposed solution offers a far simpler consensus implementation and slightly more efficient contracts in the common case (1-byte `OP_ACTIVEBYTECODE` vs. 2-byte `OP_INPUTINDEX OP_UTXOBYTECODE`).

> The complexity of this issue ultimately stems from the implementation chosen for [BIP16/P2SH](https://github.com/bitcoin/bips/blob/master/bip-0016.mediawiki), which bifurcated VM evaluation into two modes: standard and P2SH. This complicated the operational model of the VM and is particularly disruptive to the logical consistency of introspection operations between the two modes. The chosen solution focuses on simplicity and optimizing the most common cases, rather than a more complex solution which might optimize more cases. If usage of sibling redeem bytecode becomes common in real world applications, future upgrades could offer more targeted optimizations for those cases.

### Introspection Operation Range

This proposal leaves a 3 codepoint gap between the last defined operation in the current BCH instruction set (`OP_REVERSEBYTES`, `0xbc`/`188`) and the beginning of the proposed introspection operation range (`OP_INPUTINDEX`, `0xc0`/`192`).

This breaks from the recent precedent (since Nov. 2018) of adding each new opcode at the next-available codepoint. (After `OP_NOP10`/`0xb9`, `OP_CHECKDATASIG`/`0xba`, `OP_CHECKDATASIGVERIFY`/`0xbb`, and `OP_REVERSEBYTES`/`0xbc` were appended to the ISA in activation order, rather than being grouped logically with similar operations). While this may appear to complicate logic for detecting invalid codepoints (from `op > FIRST_UNDEFINED_OP_VALUE` to `isUndefined(op)`), it is equivalent in practice, as validators are optimized for evaluating valid bytecode (the common case). For example, in the Satoshi implementation, a switch statement is used to switch between valid operations – invalid opcodes only return their error after the VM iterates through the full list of possible valid opcodes.

By leaving gaps in the ISA, future upgrades may group similar operations nearer to each other. **In the long term, this may produce a more coherent ISA than one ordered only by opcode activation time.**

In the context of this proposal, the proposed gap offers up to 3 codepoints for use either by formatting operations (logically grouped with `OP_REVERSEBYTES`) or for use by additional nullary introspection operations (if the VM model is extended to incorporate new transaction-level primitives or metadata). Likewise, the 2 remaining codepoints within the introspection range (`0xce` and `0xcf`) provide space for additional unary introspection operations.

### Exclusion of Aggregation Operations

With [the partial exception of `OP_ACTIVEBYTECODE`](#differences-between-op_activebytecode-and-op_inputindex-op_utxobytecode), this proposal includes only operations which expose raw state – derived state must be computed using other VM operations. While this simplifies the proposal to a clearly defined set of "primitive" operations, certain useful, derived state elements are not yet possible to compute in all cases. For example, since the VM does not include any construction for looping or iteration, aggregate values like "total input value" and "total output value" are not always possible for contracts to compute.

While it would be possible to define aggregate operations like `OP_TXINPUTVALUE` and `OP_TXOUTPUTVALUE` to make this derived state accessible to all contracts, this proposal considers standardization of any derived state to be premature. Even with piecemeal implementation of some derived state operations, some important types of aggregated/derived state cannot be reasonably standardized, e.g. "public keys referenced by all P2PKH outputs". For contracts to support extracting this information, it's necessary to add support for generalized loops/iteration to the VM.

For this reason, this proposal does not include any aggregate operations; contract authors should instead look to proposals like [`CHIP: Bounded Looping Operations`](https://github.com/bitjson/bch-loops) for this support.

> With [`CHIP: Bounded Looping Operations`](https://github.com/bitjson/bch-loops), a `OP_TXINPUTVALUE` equivalent would require only 14 bytes:
>
> ```
> <0> <0>
> OP_BEGIN                            // loop (re)starts with index, value
>   OP_OVER OP_UTXOVALUE OP_ADD       // Add UTXO value to total
>   OP_SWAP OP_1ADD OP_SWAP           // increment index
>   OP_OVER OP_TXINPUTCOUNT OP_EQUAL
> OP_UNTIL                            // loop until next index would exceed final index
> OP_NIP                              // drop index, leaving sum of UTXO values
> ```

While not included in this proposal, future proposals may introduce aggregate operations either as a partial alternative to looping operations or as an optimization strategy for common aggregations.

### Interaction with PMv3

The [PMv3 version 3 transaction format proposal](https://github.com/bitjson/pmv3) would add two fields which don't yet exist in the v1/v2 transaction formats: [`detached signatures`](https://github.com/bitjson/pmv3#detached-signatures) and [`detached proofs`](https://github.com/bitjson/pmv3#detached-proofs). If adopted with PMv3, this proposal recommends only one additional introspection operation (`OP_INPUTDETACHED`).

Detached signatures are themselves inherently reusable across multiple inputs – rather than a specialized introspection operation, many use cases can reference a particular detached signature directly. Also, because all detached signature-covered transaction elements are themselves natively introspectable, there's little value in an operation which makes the `OP_CHECKSIG` + `OP_CHECKDATASIG` workaround more efficient for detached signatures. As such, **this proposal does not recommend any new introspection operation(s) for detached signatures**.

Detached proofs add only one new bit of information: whether or not each input is detached (`true` or `false`). Access to this information is valuable to many public covenants; if a covenant requires proofs to be detached for transaction sizes to be kept in check, the covenant needs to prevent malicious users from interacting with the covenant using transactions with non-detached proofs (leading to increased covenant transaction costs and even disabling of poorly-designed public covenants).

**To allow inspection of this information, the `OP_INPUTDETACHED` unary operation is proposed**, and the `OP_INPUTBYTECODE` operation is clarified: `(If the selected input uses a detached proof, the pushed value is the unlocking bytecode content of the detached proof.)`.

This strategy makes validation of transaction shapes trivial: `OP_INPUTINDEX OP_INPUTDETACHED OP_VERIFY` would ensure that the current contract is using a detached proof. It also maintains a consistent behavior for `OP_INPUTBYTECODE` (for both detached and standard proofs) – the pushed results of `OP_INPUTBYTECODE` would always be the unlocking bytecode regardless of whether or not the proof is detached.

> Note, the un-hashed result of `OP_INPUTBYTECODE` is most useful to practical contracts, but it's also trivial to reproduce any `detached proof hash` under this scheme: `<N> OP_INPUTBYTECODE OP_HASH256`.

<details>
<summary>No-operation alternative</summary>

Alternatively, it could be possible to avoid introducing a new `OP_INPUTDETACHED` operation at the cost of significantly increased contract complexity. Under this scheme, the `OP_INPUTBYTECODE` operation could instead be modified to push the `detached proof hash` for inputs which use detached proofs.

While this configuration would technically expose all transaction information, verifying the detached-ness of any particular input would not be trivial, and reviewing contracts for security would become more difficult.

In some cases, the size of the unlocking bytecode could simply be validated: `OP_INPUTBYTECODE OP_SIZE <32> OP_EQUAL`. If it can be guaranteed that no raw unlocking bytecode values of exactly 32-bytes exist for a particular input, this may be sufficient to guarantee that said input is detached. Otherwise, the contract will also be required to validate that a double SHA-256 preimage exists which equals the value returned by `OP_INPUTBYTECODE`. This comprehensively-secure solution would require duplicating the contents of the unlocking bytecode for each validated input, significantly increasing transaction sizes.

Finally, this solution would break the logical consistency of `OP_INPUTBYTECODE` – contracts which depend on the ability to introspect unlocking bytecode would require careful logic to identify whether or not the value returned by `OP_INPUTBYTECODE` is actually unlocking bytecode rather than the hash of that input's unlocking bytecode. In some cases, this may open contracts to vulnerabilities in which carefully "mined" detached proof hashes could deceive the contract into believing a poorly-validated detached proof hash is raw unlocking bytecode.

While this alternative strategy would save a codepoint in the BCH instruction set, it would significantly increase contract complexity, security review costs, and transaction costs. Therefore, this proposal recommends implementation of the simpler `OP_INPUTDETACHED` operation.

</details>

### Use of Single-Byte Opcodes

Earlier proposals attempted to use fewer opcodes by either [introducing all introspection operations as a single opcode](https://github.com/bitjson/op-pushstate) or by [introducing multi-byte opcodes](https://github.com/bitjson/op-pushstate/pull/1). However, [deeper analysis](https://bitcoincashresearch.org/t/bitcoin-script-multi-byte-opcodes/347/5) indicates that the BCH instruction set [might never reach 255 operations](https://bitcoincashresearch.org/t/bitcoin-script-multi-byte-opcodes/347/9) within the current VM model (future VM models are likely to have their own independent set of operations, rather than naively extending the current instruction set).

While it is likely wise to reserve both the remaining `OP_NOP4`-`OP_NOP10` range and the range from `0xf0` to `0xff` for future multi-byte opcodes (leaving room for ~6000 2-byte opcodes), jumping to multi-byte opcodes would be a premature optimization, with uncertain future benefit and immediate negative consequences.

As such – and because introspection operations are critical to all covenant use cases – this proposal specifies the proposed operations as standard, single-byte opcodes.

### Push-Only Limitation of Unlocking Bytecode

For clarity, this proposal does not modify the existing limitation (present since [BCH_2018-11-15](https://documentation.cash/protocol/forks/hf-20181115#push-only)) preventing transactions from including "non-push" operations – all operations at codepoints greater than 96 (`0x60`) – in unlocking bytecode. This limitation also prevents all operations specified in this proposal from appearing in unlocking bytecode.

This limitation is maintained to prevent a third-party malleability vector: any non-push operation can be replaced in a malleated transaction with an equivalent push operation pushing the computed result of the non-push operation. While all third-party malleability vectors would be eliminated by [PMv3's detached signatures](hhttps://github.com/bitjson/pmv3#comprehensive-malleability-protection), this CHIP leaves any loosening of the non-push limitation to future proposals.

### `OP_ACTIVEBYTECODE` Support for `OP_CODESEPARATOR`

In earlier versions of this proposal, the result of `OP_ACTIVEBYTECODE` did not account for the last executed `OP_CODESEPARATOR`. However, the current behavior is considered more conservative (`OP_ACTIVEBYTECODE` returns the active bytecode beginning after the last evaluated `OP_CODESEPARATOR`). Contracts which don't utilize `OP_CODESEPARATOR` are unaffected by this change, contracts which utilize `OP_CODESEPARATOR` can access either behavior (an earlier result of `OP_ACTIVEBYTECODE` can always be saved for use after `OP_CODESEPARATOR` is called), and some unusual contracts may be able to utilize the new behavior to optimize their bytecode size or runtime requirements.

Notably, the index of the last executed `OP_CODESEPARATOR` is available using the [`OP_CHECKSIG` + `OP_CHECKDATASIG` workaround](#motivation), so providing access to this state via `OP_ACTIVEBYTECODE` is also valuable for [operation set completeness](#operation-set-completeness).

## Implementations

- [Bitcoin Cash Node (BCHN) Merge Request 1208](https://gitlab.com/bitcoin-cash-node/bitcoin-cash-node/-/merge_requests/1208)

### Test Cases

- [Bitcoin Cash Node (BCHN) Native Introspection Tests](https://gitlab.com/bitcoin-cash-node/bitcoin-cash-node/-/blob/6fff8c761fda0ad15c9752d02db31aa65d58170f/src/test/native_introspection_tests.cpp)

## Evaluation of Alternatives

No alternative native introspection proposals are currently public, but alternative designs for several components of this proposal have been documented in the [Rationale](#rationale) section.

Several past proposals have informed the design of this proposal:

- The [initial `OP_PUSHSTATE`](https://github.com/bitjson/op-pushstate) proposal used a single opcode and templated approach. (The proposal [was withdrawn](https://bitcoincashresearch.org/t/chip-2021-02-add-native-introspection-opcodes/307/15) in favor of this CHIP.)
- An [implementation of a closely-related `OP_PUSH_TX_STATE`](http://nextchain.cash/op_push_tx_state) exists for the Bitcoin Unlimited node software in the NextChain project.
- A [multi-byte fork of the `OP_PUSHSTATE` proposal](https://github.com/bitjson/op-pushstate/pull/1) introduced the idea of [unary operations which select information by input/output index](https://github.com/bitjson/op-pushstate/pull/1#issuecomment-564072859).

Delay or rejection of this proposal may incur the following costs:

- Continued use of the inefficient workaround increases the size of the blockchain could negatively impact initial block download times and storage requirements.
- The complexity of the current workaround increases development costs and raises the barrier to entry for new developers.
- Because the current workaround is difficult to implement securely, implementation problems could result in loss of profits and reputational damage, both for the implementing company and the Bitcoin Cash ecosystem.
- Some applications and use cases will be impossible without native introspection, and competitors may outcompete BCH for these users.

## Primary Stakeholders

At least three primary stakeholder groups exist:

### Companies and Organizations

Companies and organizations currently building products utilizing introspection include:

- [General Protocols](https://generalprotocols.com/ 'General Protocols') made [AnyHedge](https://anyhedge.com/ 'AnyHedge'), a volatility risk-trading contract. They plan to build additional, non-custodial services and can support additional functionality with native introspection.

- [Tobias Ruck](https://twitter.com/TobiasRuck/ 'Tobias Ruck') created [be.cash](https://be.cash/ 'be.cash'), a refillable, offline wallet in the form of a credit card.

- [Casues Cash](https://causes.cash/ 'Casues Cash') built a modified Mecenas to support recurring payments in USD.

- [Mistcoin](https://mistcoin.org/ 'Mistcoin') has produced minable SLP tokens.

- [Flipstarter](https://flipstarter.cash/ 'Flipstarter') funding contracts utilizing native introspection might improve usability.

- [SmartBCH](https://smartbch.org/ 'SmartBCH') is building an EVM compatible Bitcoin Cash sidechain, and might use introspection as part of a bridge between the main and side chain.

### Independent Developers

A number of independent developers are developing tools and services that rely on introspection:

- [bitjson](https://gist.github.com/bitjson 'bitjson') created [CashChannels](https://blog.bitjson.com/cashchannels-recurring-payments-for-bitcoin-cash-3b274fbfa6e2 'CashChannels'), reccuring payments for Bitcoin Cash.

- [haryu703](https://github.com/haryu703 'haryu703') created [Hamingja](https://github.com/SLPVH/hamingja 'Hamingja'), a loyalty points system using non-tradable SLP token and is working on an SLP swap/trading contract.

- [Licho](https://github.com/KarolTrzeszczkowski 'Licho') created the [Last Will](https://github.com/KarolTrzeszczkowski/Electron-Cash-Last-Will-Plugin 'Last Will') contract to manage inheritance, the [Mecenas](https://github.com/KarolTrzeszczkowski/Mecenas-recurring-payment-EC-plugin 'Mecenas') contract for recurring payments, and is interested in implementing traditional games, like [NIM](https://en.m.wikipedia.org/wiki/Nim 'NIM').

- [p0oker](https://twitter.com/p0oker 'p0oker') created an [SLP Vending contract](https://github.com/p0o/yield-farming-bch-smart-contract 'SLP Vending contract') that mints tokens on-demand and is building 1) a BCH staking contract that mints tokens over time and 2) an SLP exchange contract to sell NFTs.

- [Tobias Ruck](https://twitter.com/TobiasRuck/ 'Tobias Ruck') is investigating a non-custodial on-chain gambling product.

- [James Cramer](https://twitter.com/James_Cramer 'James Cramer') is experimenting with [SLP Mint Guard](https://github.com/simpleledger/Electron-Cash-SLP/blob/cashscript-dev/lib/cashscript/slp_mint_guard.cash 'SLP Mint Guard') to protect minting batons, [SLP Vault](https://github.com/simpleledger/Electron-Cash-SLP/blob/cashscript-dev/lib/cashscript/slp_vault.cash 'SLP Vault') to help reclaim unclaimed tokens, making [tokens with minting schedules](https://github.com/simpleledgerinc/slp-mint-contracts 'tokens with minting schedules'), and building [SLP Dollars](https://github.com/simpleledgerinc/cashscript/blob/master/examples/slp_dollar.cash 'SLP Dollars') which are freezable by the issuer.

### Investors

These individuals and organizations have invested in the BCH currency and ecosystem on the premise that it can become peer to peer electronic cash for the world. These stakeholders expect the token to serve effectively as money, including in the innovative financial services which could be enabled by native introspection.

## Statements

...

### [General Protocols](https://generalprotocols.com/ 'General Protocols')

> The CHIP requires further analysis and specification before it is possible to take a strong position. GP commits to supporting this CHIP with reasonable resources. GP predicts that the benefits to BCH value and network effect will greatly outweigh the costs. Regarding the multiple implementation options available, GP sees multiple good options and encourages the active CHIP participants to choose one with reasonable logic and zero polarization.

### [p0oker](https://twitter.com/p0oker 'p0oker')

> I believe removing the current work arounds with the addition of native introspection OP Codes can improve the reliability of the smart contracts on Bitcoin Cash. Covenants are important and useful in many business use cases and it’s important to make them bulletproof!

### [Licho](https://github.com/KarolTrzeszczkowski 'Licho')

> The covenant technology have proven to be a vibrant area of BCH development. It allows us to replicate more and more of traditional banking services in a non-custodial way. The native introspection seems to be the key ingredient of the future of permissionless money.

### Tom Zander — founder [Flowee](https://flowee.org/ 'Flowee')

> This CHIP is super valuable and I fully support the direction this is going in and the ideas behind this chip. I will continue to monitor the progress with enthusiasm.

### Jimtendo - [recurr.app](https://recurr.app/ 'Recurr')

> Introspection is a useful and welcome addition to Bitcoin Cash's Smart Contract capabilities. This CHIP describes a well thought-out and efficient way of achieving it and therefore has my full support and endorsement.

### [Rosco Kalis](https://kalis.me/) - [cashscript](https://cashscript.org/)

> If this CHIP is implemented, I will commit to supporting the entire range of implemented introspection opcodes in CashScript. This greatly simplifies the compiler code that deals with introspection and will result in smaller and more efficient covenant contracts.

## Changelog

This section summarizes the evolution of this document.

- **v1.1.4 - 2021-12-1** (current)
  - Link to BCHN test cases
- **v1.1.3 - 2021-8-25** ([`29054bb8`](https://gitlab.com/GeneralProtocols/research/chips/-/blob/29054bb8215d059790edd03130b973f7626159c6/CHIP-2021-02-Add-Native-Introspection-Opcodes.md))
  - Add support for `OP_CODESEPARATOR` in `OP_ACTIVEBYTECODE` ([#27](https://gitlab.com/GeneralProtocols/research/chips/-/issues/27))
- **v1.1.2 - 2021-6-22** ([`e9e8a67d`](https://gitlab.com/GeneralProtocols/research/chips/-/blob/e9e8a67debc9c24aad1129b2df1bb0fc23cd6edc/CHIP-2021-02-Add-Native-Introspection-Opcodes.md))
  - Clarify minimal-encoding requirement for unary operation indexes
  - Clarify interaction with `CHIP: Bigger Script Integers`
  - Clarify (lack of) effect on transaction validation costs
- **v1.1.1 - 2021-6-10** ([`f501154f`](https://gitlab.com/GeneralProtocols/research/chips/-/blob/f501154fce8bec0f8572ddfef0a689f72384a35d/CHIP-2021-02-Add-Native-Introspection-Opcodes.md))
  - Added statement from stakeholder
- **v1.1 – 2021-6-8** ([`d67eb98b`](https://gitlab.com/GeneralProtocols/research/chips/-/blob/d67eb98be9db0f009859b7b945f1ac7fa4a24be9/CHIP-2021-02-Add-Native-Introspection-Opcodes.md))
  - Added version and `Changelog`
  - Extracted integration specifications into independent `CHIP Integration` sections
  - Correct and clarify resulting byte order of `OP_OUTPOINTTXHASH`
  - Clarify failure of introspection operations which attempt to exceed stack limits
- **v1.0 – 2021-6-3** ([`163f74be`](https://gitlab.com/GeneralProtocols/research/chips/-/blob/163f74bea8f526d268adf0ab6cb578b9f0bde426/CHIP-2021-02-Add-Native-Introspection-Opcodes.md))
  - Revised technical specification:
    - Convert `OP_OUTPOINTTXHASH`, `OP_OUTPOINTINDEX`, `OP_UTXOBYTECODE`, and `OP_UTXOVALUE` to unary operations
    - Group operations by arity (nullary, unary), then by P2P transaction format order
    - Distinguish `OP_ACTIVEBYTECODE` from unary `OP_UTXOBYTECODE` ([rationale](#differences-between-op_activebytecode-and-op_inputindex-op_utxobytecode))
    - Removed formatting operations (`OP_NUM2VARINT` and `OP_VARINT2NUM`) and aggregated/hashed/templated operation placeholders
    - Specified integration strategy for `CHIP: Version 3 Transaction Format (PMv3)` and `CHIP: Bigger Script Integers`
  - Added `Rationale` section, revised supporting material (`Summary`, `Deployment`, `Motivation`, `Benefits`, etc.)
- **v0.1 – 2021-3-22** ([`95a99e22`](https://gitlab.com/GeneralProtocols/research/chips/-/blob/95a99e2223671ba6b4801a6a86193b299418a7a3/CHIP-2021-02-Add-Native-Introspection-Opcodes.md))
  - Expanded `Motivation and Benefits`, `Costs and Risks`, and `List of major stakeholders`
  - Initial technical specification
- **v0 – 2021-2-21** ([`53989f7d`](https://gitlab.com/GeneralProtocols/research/chips/-/blob/53989f7d67a3afbc97ff87d6e94ef8e5c98fddf8/May%202022,%20Native%20Introspection.md))
  - Initial draft

## Copyright Notice

Copyright (c) 2021 GeneralProtocols / Research

Permission is granted to copy, distribute and/or modify this document under the terms of the [MIT license](https://gitlab.com/GeneralProtocols/research/chips/-/blob/master/LICENSE).
