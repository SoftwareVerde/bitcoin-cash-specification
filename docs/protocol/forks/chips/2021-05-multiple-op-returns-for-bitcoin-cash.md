# CHIP: Multiple OP_RETURNs for Bitcoin Cash

This CHIP was included in [HF-20210515](/protocol/forks/hf-20210515).

        Title: Multiple OP_RETURNs for Bitcoin Cash
        First Submission Date: 2021-03-12
        Owner: Benjamin Scherrey @proteusguy on Telegram
        Authors: Benjamin Scherrey
                 Earlier concept - Jonathan Silverblood
                 Technical spec - BigBlockIfTrue
        Type: Technical
        Is consensus change: No
        Status: FINAL
        Last Edit Date: 2021-05-17

## Discussions

[CHIP Discussion at Bitcoincashresearch.org](https://bitcoincashresearch.org/t/multiple-op-returns-this-time-for-real/315)

[Issues/PRs for this CHIP](https://github.com/ActorForth/Auction-Protocol/issues)

Our team is available for chat on the [ActorForth gitter](https://gitter.im/ActorForth/community).

## Summary

We propose to make presence of multiple OP_RETURN outputs qualify as standard transactions subject to the existing 223 byte limit for OP_RETURNs across all outputs of the transaction. We are silent in this proposal as to whether or not the [223 byte limit](https://github.com/bitcoincashorg/bitcoincash.org/blob/1b2008d3ac2b30a2ab26193dc8d3652fc33fb798/spec/may-2018-hardfork.md) is the correct one for BCH but are content to leave that alone in order to improve the chances of getting consensus for this change for the May 2021 fork. This makes the impact on nodes and miners as minimal and risk-free as possible while allowing developers to use OP_RETURN in a manner that justifies its core benefit - experimentation of new features/protocol updates without breaking existing systems or stressing the block chain with extraneous UTXOs which is an undesirable alternative option should this improvement not be accepted.

## Motivation and Benefits

Quite early in Bitcoin history, attempts to inject miscellaneous data into the block chain were made that made correct parsing and identification of transactions more difficult but, most importantly, bloated the UTXOs with superfluous data that potentially had a very real negative impact on operators of nodes, miners, and wallet users. The introduction of OP_RETURN with a restricted size limit that was deemed unspendable by the protocol was the compromise that protected everyone's interests. Allowing this data to be inserted but then also ignored by all who didn't care about it gave BCH developers an excellent tool in which to try out development ideas and protocol improvements in an isolated manner without introducing backwards or forward incompatibilities. Perhaps more importantly, it gave the entire BCH community an experimental model that allowed a natural maturity for protocol proposals to mature informed by actual use on the block chain rather than depend entirely on theoretical opinions on how such a protocol change might impact the BCH chain. SLP is an excellent example of such a circumstance where, after considerable efforts and real-life trials have been made, has resulted in serious proposals such as OP_GROUP to be able to be realistically considered for incorporation into the core protocol with significantly less risk than would otherwise have been possible. 

The primary limitation of OP_RETURN is that the protocol standard only allows for one instance of an OP_RETURN output per transaction which means developers who want to build on top of other OP_RETURN utilizing capabilities must either create complex parsing scripts or divide their efforts across multiple transactions. Both of these options introduce incredible complexity and often are simply not viable for demonstrating a real-world use case for how the feature would behave on the BCH chain should it be incorporated into the core protocol. 

This proposal aims to correct this minor oversight in order to bring the full potential of OP_RETURN's experimental expressiveness to the BCH chain without incurring any additional trade-offs that were part of its original design. 

The benefits of this proposal also reach users and businesses in drastically reducing foodprint when dealing with several OP_RETURN for their given use cases. Users will be able to use OP_RETURN space more efficiently, pack information in fewer transactions, use less space in mined blocks and save fees while mempool will see fewer congestions –for this specific cause.

## Specification

The only technical elements we've identified are changes to the existing node systems to remove the limit of a single OP_RETURN and to enforce the existing size limit for OP_RETURN based outputs across all aggregate OP_RETURN outputs in the transaction.

Formally, we set the rules as follows:

* An OP_RETURN output is an output with a locking script consisting of the OP_RETURN opcode followed by zero or more data pushes.
* A transaction is non-standard if the total byte size of the locking scripts of all OP_RETURN outputs is greater than 223.
* While the [BIP113](https://github.com/bitcoin/bips/blob/master/bip-0113.mediawiki) median time is less than 1621080000 (2021-05-15T12:00:00Z), a transaction is also non-standard if the number of OP_RETURN outputs is greater than one.

Some remarks:

* The size of the locking script is not just the raw data size, but includes the OP_RETURN opcode and the data push opcodes. In case of a single OP_RETURN output, only up to 220 bytes of data can be stored, because you need 1 byte for the OP_RETURN opcode, 1 byte for the OP_PUSHDATA1 opcode, and 1 byte for the length of the data. More bytes are lost if there is more than one data push operation, e.g. when the [4-byte prefix guideline](https://upgradespecs.bitcoincashnode.org/op_return-prefix-guideline/) is followed.
* In case of a single OP_RETURN output, the rules are identical to the status quo.
* In the extreme case, the rules imply a maximum of 223 OP_RETURN outputs, because the locking script of every OP_RETURN output is at least one byte (the OP_RETURN opcode itself).

## Current Implementations

* [Full implementation of the rules in Bitcoin Cash Node, including activation logic](https://gitlab.com/bitcoin-cash-node/bitcoin-cash-node/-/merge_requests/1115).
* [Implementation of the rules in Flowee, without activation logic](https://gitlab.com/FloweeTheHub/thehub/-/blob/master/libs/server/policy/policy.cpp) (allows multiple outputs immediately instead of only after 2021-05-15T12:00:00Z).

Both implementations introduce `"oversize-op-return"` as a new standardness error code, besides the existing `"multi-op-return"` error which becomes obsolete after multiple OP_RETURN outputs are allowed. In both implementations, the number 223 used in the rules can be overridden with the `-datacarriersize=<n>` command-line option.

* [Implementation of the rules in Bitcoin Unlimited, without activation logic](https://gitlab.com/bitcoinunlimited/BCHUnlimited/-/merge_requests/2453).   


## Implementation Costs and Risks

Evaluating the changes required across the popular nodes demonstrates that the impact in terms of lines of code affected are minor and isolated. For Bitcoin Unlimited there's an existing check that only one OP_RETURN exists which can be removed. A mechanism for counting the aggregate size of all the OP_RETURNs is quite simple to introduce in the same source file. Unit tests would be approximately twice the implementation size which we find typical of well designed C++ code. 

APIs that want to support multiple OP_RETURN are also easy to modify. 

## Ongoing Costs and Risks

After the initial changes are made to the core node systems no ongoing costs are anticipated. Risks are restricted to other non-standard experimental development code that may depend/demand that there only be a single OP_RETURN but, unless the code serves some purpose such as a linter or tx compliance tool, it's unlikely that such code was appropriate in the first place.

Presently the [SLP specification](https://github.com/simpleledger/slp-specifications/blob/master/slp-token-type-1.md#consensus-rules) requires its OP_RETURN to be at vout[0]. Any protocol code seeking to co-exist with SLP would want to ensure that it be in a later output to appear in the transaction in order to prevent accidental conflicts. We recommend that OP_RETURN based protocols no longer specify a positional requirement for their data but, instead, establish another mechanism for identifying which OP_RETURN belongs to them. 

Now that the limit of a single OP_RETURN has been removed, future well behaved development utilizing OP_RETURN would no longer be designed with such a presumption in mind.

### Design & Implementation Process Timeline

2020-09-21 [Initial comment on bitcoincashresearch.org](https://bitcoincashresearch.org/t/2021-bch-upgrade-items-brainstorm/130/23).

2020-10-14 [Trial implementation of proposal on Bitcoin Unlimited node](https://github.com/ActorForth/BitcoinUnlimited/commit/fd10cbd9872b157d906a03d3a4ccf7c0ddd42c65). (note: this doesn't implement aggregate size limit)

2020-10-?? Trial modifications to a [test fork of the Javascript bch-js API](https://github.com/ActorForth/bch-js) and the python Bitcash API libraries (currently in a private repo) completed.

2021-02-24 [Proposal to be introduced for the May 2021 fork](https://bitcoincashresearch.org/t/multiple-op-returns-this-time-for-real/315).

2021-03-21 This CHIP created.

2021-03-24 Proposed completion for PRs to public Bitcoin Unlimited, Bitcoin Cash Node, bch-js API, and Bitcash API projects to support this CHIP. Basically T+9 days after proposal is approved.

2021-03-13 [Flowee PR](https://gitlab.com/FloweeTheHub/thehub/-/commit/a9d3c2ee9279f2aa46890d74ce26f6e252623e72), [2](https://gitlab.com/FloweeTheHub/thehub/-/commit/45dd785f3916caa336a628d879dc7228fb73e520) support implemented by Tom Zander.

2021-03-14 [BCHN PR](https://gitlab.com/bitcoin-cash-node/bitcoin-cash-node/-/merge_requests/1115) support implemented by BigBlockIfTrue.

2021-03-25 [Bitcoin Unlimited PR](https://gitlab.com/bitcoinunlimited/BCHUnlimited/-/merge_requests/2453) support implemented by Nicolai Skye.

2021-05-15 Deployment to BCH Mainnet Chain

## Evaluation of Alternatives

Alternatives to this proposal amount to restating original alternatives to OP_RETURN (such as the multi-sig data hack), introducing complex parsing requirements to OP_RETURN outputs, or dividing OP_RETURN dependent submissions across multiple transactions. All are more complex and risky than this proposal. 

Jonathan Silverblood identified 3 other alternative proposals considered in 2020, [BUIP149: Delimited OP_RETURNs](https://bitco.in/forum/threads/buip149-delimited-op_returns.26362/), [BUIP139](https://bitco.in/forum/threads/buip139-multiple-op_return-with-less-rules.24951/), and [BUIP140](https://bitco.in/forum/threads/buip140-multiple-op_return-with-shared-size-limit.24952/). 

BUIP149 puts multiple OP_RETURNs in a single output and requires complex parsing scripts and potentially could collide with existing protocols using OP_RETURNs already including SLP. It also proposes to change the maximum size of OP_RETURN data in a transaction. Community efforts to incorporate this option are significantly higher than this CHIP.

BUIP139 is actually quite similar to this CHIP except it proposes that there be some fixed limit to the number of OP_RETURNs. One reason why BUIP139 should be considered inferior is because it makes it more difficult to change the op_return max bytes in the future, as it would magnify the impact, for example:

If BUIP139 took place, and was set to 4 op_returns / transaction, then if we want to change the byte size it now has to be an even number of 4. If we naively increase by 10 bytes, then a total of 40 more bytes can be used, rather than the 10 byte intended.

BUIP140 is similar to this CHIP but was just not taken forward. Major difference is that it debates or introduces the explicit possibility of increasing the total size of OP_RETURN data but does not require it.

Without the aggregate size consideration, the future impact of changing the legal sizes of OP_RETURN becomes more profound and possibly difficult to predict but saves tx creators from having to track a total across all OP_RETURNs. The opinion of the author is that the days of being able to consider parts of transactions independent of others are long gone so this is not a meaningful shortcoming. Size reductions would be profound and dangerous changes and are unlikely to be practical to deploy. Size increases should be based on empirical demonstrations of value through experimental apps that push these limits while demonstrating real value to the BCH ecosystem. Regardless of the ultimate size, having that quantity come from a shared pool helps allow OP_RETURN based protocols to be expressed naturally in a manner more closely resembling what their ultimate core protocol implementations would look like rather than having to perform hacks to fit within a per-OP_RETURN limit that would necessarily be smaller. Again these are future considerations outside of the direct scope of this CHIP.

## List of Major Stakeholders


## Statements

### Full node developers

from Tom Zander, owner [Flowee](https://flowee.org)

> This change will have little to no cost on our ecosystem while enabling more usecases to be added over time, to be developed without touching consensus rules in the traditional permissionless manner. I fully support this proposal and have code ready to ship for this.

from freetrader, lead maintainer of Bitcoin Cash Node

> This is a simple and logical change that provides more flexibility for OP_RETURN users without affecting the trade-offs associated with the limit. The proposal has been implemented in a BCHN change request and a majority of BCHN maintainers supports activating this change on 15 May 2021.

> While this CHIP arrived at a fairly late moment, we believe that sufficient awareness has been raised such that it can nevertheless be activated in May provided all major full node clients can implement it by then.

### Major businesses

from Benjaim Scherrey

> My company, [Biggest Fan Productions](https://biggestfan.net), has developed a [protocol](https://github.com/ActorForth/Auction-Protocol/blob/main/proposal-spec.md) that utilizes SLP NFTs & FTs to perform on-chain tracked open call auctions for assets such as concert tickets. To fully be able to represent the state of the auction in a trustless manner it requires an additional OP_RETURN to be allowed in BCH transactions. This is notice of my support and personal interest in this CHIP.

### Miners and pools

I have sought out contacts for such organizations and have received no responses. Appreciate any follow up on contacting these entities.

### Wallets and clients

I have sought out contacts for such organizations and have received few responses. Appreciate any follow up on contacting these entities.

An ElectronCash SLP wallet dev had no strong opinion on this CHIP (or the CHIP process) and registered no objection when asked.

### Application Developers

from Jonathan Silverblood:

> I believe multiple OP_RETURNs should be adopted, it is highly valuable as it makes it possible for OP_RETURN based protocols to work together to create value. I also believe that counting the aggregate number of bytes is in line with the intent of the original functionality.

from Joey Masterpig

> I would like to add my support to this proposal as a Stakeholder. Founder of the upcoming SLP NFT game enter-the-sphere.com . Co-Founder of Spice Token, and a Director of the SLP Foundation.

> I believe having multiple_opreturns will add some interesting possibilities for NFTs for Enter The Sphere, our token solution needs to be as competitive as possible, and anything that expands the chance of something innovative being done on SLP, is something I support.

> As I understand, implementation of this change will allow multiple assets to be on a single tx, something that can be very useful for pairing NFTs with other assets. A function that allows us to link NFT items with other assets easier than current.

> This is my personal opinion and support as a non-technical stakeholder, this is not a technical endorsement nor have i reviewed deeply about whether these changes have cons on a technical basis (as far as I understand there is none).

Stoyan Zhekov, bch-js developer

> I think Multiple OP_RETURN CHIP will provide a way for better NFTs - both NFT (SLP) payload and BCP payload can be parts of one transaction, which will reduce the number of queries to retrieve the external content.

### Users

from Leandro Di Marco

> I see this initiative with great value for users, who will engage with the OP_RETURN resource more efficiently. And while such optimization would seem samll at the moment, it will surely become more relevant as Bitcoin Cash grows in adoption.

## Copyright

BSD 3-Clause License

Copyright (c) 2018, 2020 Benjamin Scherrey, BiggestFan Productions Co. Ltd
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.