# CHIP-2021-03: Bigger Script Integers

> OWNERS: [Jason Dreyzehner](https://bitjson.com/), [Rosco Kalis](https://github.com/rkalis), [Jonathan Silverblood](https://gitlab.com/monsterbitar)
>
> DISCUSSION: [Bitcoin Cash Research](https://bitcoincashresearch.org/t/improve-utility-of-script-calculations-larger-numbers-op-mul/39), [Telegram](https://t.me/joinchat/SeRFuFmba7tWOcKh)
>
> VERSION: 1.0
>
> MILESTONES: **[Published](https://gitlab.com/GeneralProtocols/research/chips/-/blob/master/CHIP-2021-02-Bigger-Script-Integers.md)**, **[Specification](#technical-specification)**, **[Testnet](https://read.cash/@bitcoincashnode/bch-testnet4-for-may-2022-network-upgrade-updated-2021-11-23-95a21d51)**, **Accepted ([BU](https://twitter.com/BitcoinUnlimit/status/1460394221240786956) - [BCHN](https://twitter.com/bitcoincashnode/status/1460424339816284161) - [Knuth](https://twitter.com/KnuthNode/status/1460622308607938579) - [Verde](https://twitter.com/joshmgreen/status/1460592944516317185) - [Bitauth](https://twitter.com/Bitauth/status/1460371045207232512))**, Deployed (May 15th, 2022).

## Summary

This proposal expands the integer range allowed in BCH contracts (from 32-bit to 64-bit numbers) and re-enables the multiplication opcode (`OP_MUL`).

## Deployment

Deployment of this specification is proposed for the May 2022 upgrade.

## Motivation

BCH virtual machine (VM) math operations are currently limited to signed 32-bit integers, preventing contracts from operating on values larger than `2147483647` – representing satoshis, this is ~21 BCH. Workarounds which allow contracts to emulate higher-precision math are often impractical, difficult to secure, and significantly increase transaction sizes.

This unusually-low limit on arithmetic operations has been present since the earliest Bitcoin release to avoid standardizing a strategy for overflow handling ([though 64-bit math was always used internally](#arithmetic-operation-overflows)). Since the development of covenants, this unusual overflow-handling strategy has become a source of contract vulnerabilities and a barrier to real-world applications. Few remaining computing environments operate using 32-bit integers, and this limit has never been relevant to [worst-case transaction validation performance](https://github.com/bitjson/bch-vm-limits#pre-deployment-hashing-limit-benchmark).

## Benefits

By allowing contracts to efficiently operate on larger numbers, this proposal enables new use cases, improves contract security, and reduces transaction sizes.

### Larger Contract Values

By expanding the upper bound of arithmetic inputs to `9223372036854775807`, contracts can efficiently operate on values larger than the total possible satoshi value of any transaction output ([approx. `2100000000000000`](#limiting-arithmetic-operations-to-8-byte-script-numbers)). This enables contracts to manage balances of any size, clearing the way for large, public decentralized applications.

Expanded arithmetic capabilities also **enable greater practical use of new payment and financial systems** including: scheduled and recurring payments, risk-hedging contracts, synthetic assets, decentralized exchanges, inheritance and treasury management systems, crowdfunding and crowdmatching applications, loyalty point and token systems, delayed-withdrawal vaults (and other contract security strategies), and more.

### Safer Contracts

This proposal obviates the need for higher-precision math emulation. As a result, existing applications can be simplified, making them easier to develop and review. Additionally, by making arithmetic overflows less common (many common operations overflow 32 bits, but few approach 64 bits), contracts are less likely to include vulnerabilities or faults which can expose users to attacks and losses.

### Reduced Transaction Sizes

Because this proposal allows existing contracts to remove higher-precision math emulation, transactions employing these contracts are reduced in size. This reduces transaction fees for contract users, and it reduces storage and bandwidth costs for validators.

## Costs & Risk Mitigation

The following costs and risks have been assessed.

### Modification to Transaction Validation

Modifications to VM limits have the potential to increase worst-case transaction validation costs and expose VM implementations to Denial of Service (DOS) attacks.

**Mitigations**: migration from 32-bit to 64-bit arithmetic has no impact on [worst-case validation performance](https://github.com/bitjson/bch-vm-limits#pre-deployment-hashing-limit-benchmark). (Notably, most implementations already use 64-bit or larger number representations internally, and overflow-checked 64-bit math is also available natively in most programming languages and computing environments.) Even at a significantly higher [practical limit approaching 10,000 operations](https://github.com/bitjson/bch-vm-limits), 64-bit arithmetic operations are thousands to millions of times less expensive than [existing scenarios](https://github.com/bitjson/bch-vm-limits#benchmarks) (varies by environment and implementation).

### Node Upgrade Costs

This proposal affects consensus – all fully-validating node software must implement these VM changes to remain in consensus.

These VM changes are backwards-compatible: all past and currently-possible transactions remain valid under these new rules.

### Ecosystem Upgrade Costs

Because this proposal only affects internals of the VM, most wallets, block explorers, and other services will not require software modifications for these changes. Only software which offers VM evaluation (e.g. [Bitauth IDE](https://github.com/bitauth/bitauth-ide)) will be required to upgrade.

Wallets and other services may also upgrade to add support for new contracts which will become possible after deployment of this proposal.

### Protocol Implementation Costs

By requiring support for 64-bit math, this proposal could increase the cost of new protocol implementations in unusual programming languages which lack native support for overflow-checked, signed, 64-bit math.

**Mitigations**: nearly all modern platforms and languages include native support for 64-bit or larger integers. Additionally, transaction output values are already encoded using unsigned, 64-bit integers, so many BCH software libraries already include support for 64-bit integers.

> For example, until recent years, JavaScript supported only 64-bit floating point numbers (IEEE-754). While JavaScript now widely supports [`BigInt`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt), many older BCH JavaScript libraries still include big integer polyfills to support encoding of transaction output values without using `BigInt`. These polyfills typically support 64-bit math, making implementation easier.

## Technical Specification

All BCH VM operations which operate on `Script Numbers` (A.K.A. `CSCriptNum`) are modified to support values within the expanded range of 8 bytes (64 bits), and `OP_MUL` (`0x95`/`149`) is re-enabled.

### Script Number Range

The `Script Number` format (A.K.A. `CSCriptNum`) is a consensus-standardized, variable-length, signed integer format used by all VM operations which consume or produce numeric values. In practice, the allowable range of the Script Number format is limited by the parsing of Script Number values within all VM operations which consume Script Numbers.

Prior to activation of this proposal, Script Number parsing is limited to `4` byte stack values. After activation, Script Number parsing must be limited to `8` byte stack values. This expands the available range from a minimum of `0xffffffff` (`-2147483647`) and maximum of `0xffffff7f` (`2147483647`) to a minimum of `0xffffffffffffffff` (`-9223372036854775807`) and maximum of `0xffffffffffffff7f` (`9223372036854775807`).

> Note: an unusual property of the existing Script Number format reduces its negative range by `1`: the Script Number format can hypothetically represent both "positive" `0` (`0x`, the empty stack item) and "negative" `0` (`0x80`) (despite [minimal-encoding requirements preventing this in practice](https://reference.cash/protocol/forks/2019-11-15-minimaldata)). As such, the minimum Script Number which can be represented in 8 bytes is `-9223372036854775807` rather than `-9223372036854775808` (the minimum signed 64-bit integer in C-like programming languages).

All operations which consume Script Numbers must immediately fail evaluation if an input is received which exceeds the allowed range. (Note: since 2019-11-15, Script Numbers are also required by consensus to be [minimally encoded in most cases](https://reference.cash/protocol/forks/2019-11-15-minimaldata); this rule remains in effect.)

#### Notice of Possible Future Expansion

While unusual, it is possible to design contracts which rely on the rejection of otherwise-valid Script Numbers which are larger than 8 bytes. Contract authors are advised that future upgrades may further expand the supported range of BCH VM Script Numbers beyond 8 bytes.

**This proposal interprets such failure-reliant constructions as intentional** – they are designed to fail unless/until a possible future network upgrade in which larger Script Numbers are enabled (i.e. a contract branch which can only be successfully evaluated in the event of such an upgrade).

> As always, the security of a contract is the responsibility of the entity locking funds in that contract; funds can always be locked in insecure contracts (e.g. `OP_DROP OP_1`). This notice is provided to warn contract authors and explicitly codify a network policy: the possible existence of poorly-designed contracts will not preclude future upgrades from further expanding the range of Script Numbers.
>
> To ensure a contract will always fail when arithmetic results overflow or underflow 8-byte Script Numbers (in the rare case that such a behavior is desirable), that behavior must be either 1) explicitly validated or 2) introduced to the contract prior to the activation of any future upgrade which expands the range of Script Numbers.

#### `Script Number` Test Vectors

<details>
<summary>Valid Script Numbers</summary>

| Hex                  | Value                          |
| -------------------- | ------------------------------ |
| `0x` (empty)         | 0                              |
| `0x01`               | 1                              |
| `0x02`               | 2                              |
| `0x03`               | 3                              |
| `0x7e`               | 126                            |
| `0x7f`               | 127                            |
| `0x8000`             | 128                            |
| `0x8100`             | 129                            |
| `0x8200`             | 130                            |
| `0xff00`             | 255                            |
| `0xfe7f`             | 32766                          |
| `0xff7f`             | 32767                          |
| `0x008000`           | 32768                          |
| `0x018000`           | 32769                          |
| `0x028000`           | 32770                          |
| `0xffff00`           | 65535                          |
| `0xffffff00`         | 16777215                       |
| `0xfeff7f`           | 8388606                        |
| `0xffff7f`           | 8388607                        |
| `0x00008000`         | 8388608                        |
| `0x01008000`         | 8388609                        |
| `0x02008000`         | 8388610                        |
| `0xfeffff7f`         | 2147483646                     |
| `0xffffff7f`         | 2147483647                     |
| `0x0000008000`       | 2147483648                     |
| `0x0100008000`       | 2147483649                     |
| `0xffffffff7f`       | 549755813887                   |
| `0x000000008000`     | 549755813888                   |
| `0xffffffffff7f`     | 140737488355327                |
| `0x00000000008000`   | 140737488355328                |
| `0xffffffffffff7f`   | 36028797018963967              |
| `0x0000000000008000` | 36028797018963968              |
| `0xffffffffffffff7f` | 9223372036854775807 (maximum)  |
| `0xffffffffffffffff` | -9223372036854775807 (minimum) |
| `0xfeffffffffffffff` | -9223372036854775806           |
| `0xffffffffffffff`   | -36028797018963967             |
| `0xffffffffffff`     | -140737488355327               |
| `0xffffffffff`       | -549755813887                  |
| `0xffffffff`         | -2147483647                    |
| `0xfeffffff`         | -2147483646                    |
| `0xfdffffff`         | -2147483645                    |
| `0xffffff80`         | -16777215                      |
| `0x01008080`         | -8388609                       |
| `0x00008080`         | -8388608                       |
| `0xffffff`           | -8388607                       |
| `0xfeffff`           | -8388606                       |
| `0xfdffff`           | -8388605                       |
| `0xffff80`           | -65535                         |
| `0x018080`           | -32769                         |
| `0x008080`           | -32768                         |
| `0xffff`             | -32767                         |
| `0xfeff`             | -32766                         |
| `0xfdff`             | -32765                         |
| `0xff80`             | -255                           |
| `0x8180`             | -129                           |
| `0x8080`             | -128                           |
| `0xff`               | -127                           |
| `0xfe`               | -126                           |
| `0xfd`               | -125                           |
| `0x82`               | -2                             |
| `0x81`               | -1                             |

</details>

<details>
<summary>Invalid Script Numbers</summary>

| Hex                    | Error                                                            |
| ---------------------- | ---------------------------------------------------------------- |
| `0x000000000000008000` | 9223372036854775808 exceeds the maximum Script Number.           |
| `0x000000000000008080` | -9223372036854775808 is less than the minimum Script Number.     |
| `0x00`                 | Non-minimal encoding (for `0x`/`0`)                              |
| `0x0000`               | Non-minimal encoding (for `0x`/`0`)                              |
| `0x80`                 | Non-minimal encoding (for `0x`/`0`)                              |
| `0x0080`               | Non-minimal encoding (for `0x`/`0`)                              |
| `0x0180`               | Non-minimal encoding (for `0x81`/`-1`)                           |
| `0x010080`             | Non-minimal encoding (for `0x81`/`-1`)                           |
| `0x01000080`           | Non-minimal encoding (for `0x81`/`-1`)                           |
| `0x0100000080`         | Non-minimal encoding (for `0x81`/`-1`)                           |
| `0xffffffffffff0080`   | Non-minimal encoding (for `0xffffffffffff80`/`-281474976710655`) |

</details>

### Arithmetic Operation Overflows

All arithmetic VM operations must use (C-like) signed, 64-bit integer operations with overflow detection (e.g. using the [X86-64 GNU C Integer Overflow Builtins](https://gcc.gnu.org/onlinedocs/gcc/Integer-Overflow-Builtins.html), `__builtin_ssubll_overflow`, `__builtin_saddll_overflow`, and `__builtin_smulll_overflow`, for `OP_SUB`, `OP_ADD`, and `OP_MUL`, respectively). If an operation overflows or underflows, the operation must immediately fail evaluation.

Additionally, operations which produce precisely the minimum value (`-9223372036854775808`) – requiring 9 bytes to be encoded as a Script Number – **must [immediately fail evaluation](#disallowance-of-9-byte-script-numbers-from-arithmetic-results)**. (Implementation note: this error can be enforced during Script Number re-encoding.)

### Re-Enable Multiplication (`OP_MUL`)

The `OP_MUL` multiplication operation is re-enabled (at `0x95`/`149`, its original codepoint). `OP_MUL` performs C-style, overflow-checked, integer multiplication (e.g. using the [X86-64 GNU C Integer Overflow Builtins](https://gcc.gnu.org/onlinedocs/gcc/Integer-Overflow-Builtins.html), `__builtin_smulll_overflow`).

## Rationale

This section documents design decisions made in this specification.

### Inclusion of `OP_MUL`

The `OP_MUL` operation was excluded from the [upgrade restoring disabled opcodes (May 2018)](https://reference.cash/protocol/forks/may-2018-reenabled-opcodes) because a solution for handling overflows was not yet decided; it was expected that `OP_MUL` would be re-enabled during another upgrade which expanded the accepted range of Script Number arithmetic inputs.

Because this proposal offers a solution for arithmetic underflows and overflows, `OP_MUL` is no longer blocked. Re-activation is included directly in this proposal because the two changes are strongly connected and will benefit from a combined review.

### Alternative Overflow Behavior

Until this proposal, overflows have only been prevented indirectly: VM implementations typically employ signed 64-bit integers internally, and because numeric inputs to all operations have been limited to 4-byte Script Numbers, no operations are capable of producing Script Number results larger than 5 bytes. (While inputs are constrained to 4 bytes, 5-byte results are allowed.) With this proposal, overflows would be handled explicitly: they cause an evaluation to immediately fail.

Alternatively, this proposal could attempt to maintain the previous "undefined" overflow behavior, where overflows aren't explicitly handled by the VM. However, that behavior would require a much less efficient implementation: to support 64-bit multiplication, VM implementations would be required to use at least 128-bit arithmetic internally (while still preventing contracts from using inputs larger than 64 bits).

> To demonstrate, the maximum 64-bit/8-byte input `0xffffffffffffffff` (`18446744073709551615`), multiplied by itself is `0xfffffffffffffffe0000000000000001` (`340282366920938463426481119284349108225`), which requires 128-bits/16 bytes to represent.

The overflow handling behavior implemented by this proposal is both more common (among popular programming languages and computing environments) and more efficient than the existing undefined overflow handling strategy. Additionally, this proposal's explicit overflow handling strategy also enables potential future operations (e.g. exponentiation) to be enabled using simple, common implementations.

### Limiting Arithmetic Operations to 8-byte Script Numbers

This proposal limits all inputs and outputs of arithmetic operations to the range which can be encoded in 8-byte Script Numbers. This range is nearly equivalent to the range of signed, 64-bit integers ([excluding only one value](#disallowance-of-9-byte-script-numbers-from-arithmetic-results)), and in the positive range (`9223372036854775807` maximum) significantly exceeds the largest possible value of any transaction output: `~2100000000000000` (`21 million BCH * 100 million satoshis`).

Because signed, 64-bit integer arithmetic is natively implemented in most computing environments, this limit also offers practically-equivalent worst-case performance vs. the existing 4-byte Script Number limitation. (Notably, derivatives of the Satoshi implementation already use 64-bit numbers internally, but enforce the lower 4-byte limit to prevent overflows.) As such, an 8-byte limit significantly expands the functionality of the VM without impacting [worst-case transaction validation costs](https://github.com/bitjson/bch-vm-limits#pre-deployment-hashing-limit-benchmark) or VM implementation complexity.

A future upgrade which adds support for significant subdivision of satoshi values could create demand for Script Numbers with a greater range than 8 bytes. However, given a maximum possible satoshi supply of `~2100000000000000`, the `9223372036854775807` maximum provides ample room for 1/1000th satoshi subunits before representing even the largest balances might require arithmetic workarounds. And even in these cases, many contracts will be able to either 1) emulate support for larger arithmetic operations using multi-step computations, or 2) operate on rounded values for very large numbers. Given this additional flexibility, the 8-byte limit is likely sufficient until a distant future upgrade.

> Note: a popular BCH token protocol, [Simple Ledger Protocol (SLP)](https://slp.dev/), technically allows tokens to be created with much greater divisibility than BCH – BCH supports 8 decimal places (satoshis), while SLP tokens can support up to 18. This proposal does not consider these unusual cases to currently warrant a greater arithmetic range: divisibility beyond that of BCH is unlikely to be practically useful in commerce, and if `satoshis` become insufficiently divisible in the distant future, arithmetic range can be increased at the same time as divisibility.
>
> **Users of higher-level protocols like SLP who intend to employ VM arithmetic are advised to target an arithmetic range less than or equal to satoshis for maximum contracting flexibility.**

### Continued Separation of Cryptographic and Arithmetic Operations

Past proposals have suggested larger arithmetic limits in an effort to support number sizes useful to cryptosystems. While [deeper analysis](https://bitcoincashresearch.org/t/improve-utility-of-script-calculations-larger-numbers-op-mul/39/15) indicates that larger arithmetic limits are unlikely to be useful in implementing new cryptosystems, such larger limits could negatively impact transaction validation costs.

In short, BCH VM cryptographic operations [do not operate on numbers](https://bitcoincashresearch.org/t/improve-utility-of-script-calculations-larger-numbers-op-mul/39/18): they are high-level APIs which operate on data structures representing (sets of) numbers. Compatibility between arithmetic and cryptographic operations would be complex and likely introduce performance bottlenecks.

> Note, limiting arithmetic inputs to 8-byte Script Numbers **does not prevent larger numbers from being represented and used elsewhere in the BCH VM instruction set**. (In fact, larger numbers are already in use within signatures and public keys.) Future proposals could introduce new operations specifically designed to perform mathematical operations on cryptographic data structures (including greater than 8-byte Script Numbers).

### Inclusion of Future Expansion Notice

The [Notice of Possible Future Expansion](#notice-of-possible-future-expansion) is included in this specification to avert future controversy by documenting the proposal's intent with respect to future (not-yet specified) upgrades: **the BCH VM is not guaranteed to forever limit Script Numbers to 8 bytes**.

If this were not clarified, any future Script Number upgrade proposals could be more easily mischaracterize by publicizing deposits made to contracts that are [intentionally designed to rely on the 8-byte overflow behavior](https://bitcoincashresearch.org/t/improve-utility-of-script-calculations-larger-numbers-op-mul/39/12). With this notice, such misdirection might be more easily identified as disingenuous.

### Disallowance of 9-byte `Script Numbers` from Arithmetic Results

Only one 9-byte Script Number can be represented within the signed 64-bit integer range to be used by VM arithmetic operations after activation of this proposal: `-9223372036854775808`. This precise value is disallowed (by limiting all Script Number arithmetic inputs and outputs to 8 bytes) to simplify both VM implementation and contract security analysis.

If this 9-byte value were allowed in arithmetic results, it would break the assumption that all valid arithmetic results are also valid arithmetic inputs. In some covenants, this could present a subtle exploit: if an attacker can force the contract to somehow retain this precise 9-byte result, the attacker could place the covenant in an unintended state, preventing the 9-byte result from being successfully passed into other arithmetic operations. Furthermore, analyzing contracts for this vulnerability requires detailed information about the possible numeric ranges of arithmetic inputs and outputs, creating an unnecessary burden for static contract analysis.

For example, if the 9-byte value were allowed, the script `<-9223372036854775807> OP_1SUB OP_1ADD` would successfully produce the 9-byte value after `OP_1SUB`, but the resulting 9-byte Script Number would be rejected by `OP_1ADD`. Implementations could add a special case for handling this particular signed 64-bit integer, 9-byte Script Number, but the corresponding positive number (`9223372036854775808`) is also not representable as a signed 64-bit integer (in most computing environments), so an operation like `<-9223372036854775808> OP_NEGATE` would also overflow.

## Implementations

_(in progress)_

### Test Cases

_(in progress)_

## Evaluation of Alternatives

Alternative designs for several components of this proposal have been documented in the [Rationale](#rationale) section, and several past proposals have also informed the design of this proposal:

### 128-bit Integers

An [earlier proposal for 128-bit integers](https://gist.github.com/rkalis/eabdbba283f3807c0e38bd677672b6ae) would also enable up to 128-bit arithmetic operations. The larger 128-bit range [may impact worst-case validation performance](https://gist.github.com/bitjson/78967c2affddaf3b7d1ab4dee71a940f#prototype--benchmark-dos-viability), and implementation is likely to be more complex in many computing environments.

While future proposals could further expand the range of VM arithmetic operations, [64-bit math is likely sufficient even for operation on 1/1000th "fractional satoshis"](#limiting-arithmetic-operations-to-8-byte-script-numbers), so further expansion requires additional research.

### NextChain BigNum

[NextChain BigNum](http://nextchain.cash/bignum) would enable up to 4096-bit integer arithmetic, add the `OP_SETBMD`, `OP_BIN2BIGNUM`, and `OP_BIGNUM2BIN` operations, and introduce "type" information to all stack items (with a new `BigNum` type).

Implementation of NextChain BigNum is notably more complex than other proposals, and it is unclear whether support for larger arithmetic inputs would have practical applications (see [Continued Separation of Cryptographic and Arithmetic Operations](#continued-separation-of-cryptographic-and-arithmetic-operations)).

## Primary Stakeholders

At least five primary stakeholder groups exist:

### Node Developers

At least six node implementations must be upgraded:

- [Bitcoin Cash Node](https://bitcoincashnode.org/)
- [Bitcoin Unlimited](https://www.bitcoinunlimited.info/)
- [BCHD](https://bchd.cash/)
- [Flowee](https://flowee.org/)
- [Bitcoin Verde](https://bitcoinverde.org/)
- [Knuth](https://kth.cash/)

### Library Developers

At least five libraries must be upgraded:

- [BitPay](https://bitpay.com/) developed the [bitcore-lib-cash](https://github.com/bitpay/bitcore/tree/master/packages/bitcore-lib-cash) library, which supports Script execution.
- [Jason Dreyzehner](https://github.com/bitjson) developed the [libauth](https://github.com/bitauth/libauth) library, which supports Script execution.
- [Pokkst](https://github.com/pokkst) developed the [bitcoincashj](https://github.com/pokkst/bitcoincashj) library, which supports Script execution.
- [Dagur Valberg Johansson](https://github.com/dagurval/) developed the [python-bitcoincash](https://github.com/dagurval/python-bitcoincash) library, which supports Script execution.
- [Tobias Ruck](https://github.com/eyeofpython) developed the [Iguana](https://github.com/be-cash/iguana) library, which supports Script execution.

### Contract Developers

Contract developers affected by existing limits include:

- [General Protocols](https://generalprotocols.com/) created [AnyHedge](https://anyhedge.com/), a volatility risk-trading contract. AnyHedge contracts are limited to ~$15k and have a slight math error due to workarounds.
- [Licho](https://github.com/KarolTrzeszczkowski) created a [Last Will](https://github.com/KarolTrzeszczkowski/Electron-Cash-Last-Will-Plugin) contract to manage inheritance and the [Mecenas](https://github.com/KarolTrzeszczkowski/Mecenas-recurring-payment-EC-plugin) contract for recurring payments. These contracts are limited to ~21 BCH (~$10k).
- [Shomari Prince](https://github.com/nyusternie) created [Causes Cash](https://causes.cash/), which includes a modified Mecenas to support recurring payments in USD. These contracts are limited to ~21 BCH (~$10k).
- [James Cramer](https://github.com/jcramer/) created experimental [SLP Mint Guard](https://github.com/simpleledger/Electron-Cash-SLP/blob/cashscript-dev/lib/cashscript/slp_mint_guard.cash) contracts and [tokens with minting schedules](https://github.com/simpleledgerinc/slp-mint-contracts). These contracts are currently not limited, but to execute the proposed roadmap they will be very limited as they will need to perform arithmetic on SLP token amounts (which can have more decimals and lower USD values than BCH).
- [p0oker](https://github.com/p0o/) created an [SLP vending contract](https://github.com/p0o/yield-farming-bch-smart-contract) that mints tokens on-demand and is building a BCH staking contract that mints tokens over time and an SLP exchange contract to sell NFTs. Similar to James Cramer's contracts, these contracts will be very limited as they need to work with SLP amounts.
- [Jason Dreyzehner](https://github.com/bitjson) created [CashChannels](https://blog.bitjson.com/cashchannels-recurring-payments-for-bitcoin-cash-3b274fbfa6e2), recurring payments for Bitcoin Cash. These channels are limited to ~21 BCH (~$10k).

### Node Operators & Miners

_(in progress)_

### Investors

These individuals and organizations have invested in the BCH currency and ecosystem on the premise that it can become peer to peer electronic cash for the world. These stakeholders expect the token to serve effectively as money, including in the innovative financial services which could be enabled by expanded arithmetic support.

## Statements

### Node Developers

_(in progress)_

### Library Developers

_(in progress)_

### Contract Developers

_(in progress)_

#### General Protocols

Developing workarounds to this limitation has cost General Protocols a large amount of time and money. This is still ongoing as the added complexity makes further smart contract changes more difficult. Because of the required code to address this, there are also other contract features that do not fit within the contract bytecode size limits.

### Node Operators & Miners

_(in progress)_

### Investors

_(in progress)_

## Changelog

This section summarizes the evolution of this document.

- **v1.0 – 2021-6-9** (current)
  - Completed technical specification
  - Added `Rationale` section, revised supporting material (`Summary`, `Deployment`, `Motivation`, `Benefits`, `Evaluation of Alternatives`, etc.)
- **v0 – 2021-2-21** ([`32e9d5ed`](https://gitlab.com/GeneralProtocols/research/chips/-/blob/32e9d5ed0ebffd13b351f26d4c4f9370598c9933/CHIP-2021-02-Bigger-Script-Integers.md))
  - Initial draft

## Copyright Notice

Copyright (c) 2021 GeneralProtocols / Research

Permission is granted to copy, distribute and/or modify this document under the terms of the [MIT license](https://gitlab.com/GeneralProtocols/research/chips/-/blob/master/LICENSE).
