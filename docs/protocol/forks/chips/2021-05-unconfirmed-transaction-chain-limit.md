# CHIP: Unconfirmed Transaction Chain Limit

This CHIP was included in [HF-20210515](/protocol/forks/hf-20210515).

## Authors

**CHIP Owner:**  
Josh Green, Software Verde

**Contributors:**

    John Jamiel, Software Verde
    Doug McCollough, City of Dublin, OH
    Emil Oldenburg, Bitcoin.com
    Roger Ver, Bitcoin.com
    Mark Lamb, CoinFLEX

## Summary
**Version 1.2.1**

When a transaction is first transmitted on the Bitcoin Cash network, it is considered “unconfirmed” until it is “mined” into a block.  These transactions that are not yet mined are also referred to as “zero-conf” transactions.  Transactions are dependent upon other transactions, such that they are chained together; the value allocated by one transaction is then spent by a subsequent transaction.  

Currently, the Bitcoin Cash network only permits transactions to be chained together 50 times before a block must include them.  Transactions exceeding the 50th chain are often ignored by the network, despite being valid.  Once a transaction is submitted to the network, it cannot be revoked. This situation, when encountered, can be extremely difficult to remedy with today’s available tools and simultaneously creates an unnecessary amount of complexity when being accounted for by network and applications developers. This CHIP is a formal request to remove the unconfirmed transaction chain limit=depth (50tx) and size (101kb) entirely from the Bitcoin Cash ecosystem.

**Discussion URL:** https://bitcoincashresearch.org/t/chip-unconfirmed-transaction-chain-limit/302/32

**Full Change History URL:** https://github.com/softwareverde/bitcoin-cash-chips/blob/master/unconfirmed-transaction-chain-limit.md


## Motivations

Transactions exceeding the unconfirmed transaction chaining limit are often ignored by the network, despite being considered a valid transaction. For these transactions, this leaves the value transferred in an ambiguous state: it has been transferred, but some (or all) of the network may not record this transfer.  Once value has been transferred by a transaction, the balance may not be distributed in a different proportion or to a separate receiver (often known as a “double-spend”) due to the network’s convention to prefer the first-seen transfer rather than the newer transfer.  Therefore, the only viable path forward in this scenario is to transmit the same (perfectly identical) transaction again to the network.  However, if the wallet or service is connected to peers that accepted the transaction, rebroadcasting the same transaction does not cause the connected peers to retransmit it themselves--causing the transaction to be stuck with no recourse other than hoping to connect to a new peer that has not yet seen the transaction.  For this reason, it is important that all nodes agree on the unconfirmed transaction chain limit.  

Additionally, determining if the transaction was not accepted by the network is a difficult to solve problem with the current available toolset.  Error-responses from nodes rejecting a transaction have not been standardized, and often times nodes will silently reject the transaction--sometimes the node may not even be aware that the transaction is invalid because its dependent has not been seen yet, and the node itself cannot determine the transaction’s chain depth.

It is also not always known to the user, service, or wallet how deep the unconfirmed transaction already is when it’s received; it’s entirely possible the coins received are at the limit, and determining that state can be near-impossible without the help of a full-node.

The problem from a user/app’s perspective is that they have created a valid transaction and are given little indication that it will not be mined within a block.  The tools for recourse are limited, and the tools for monitoring for such a situation is also limited.


The unconfirmed transaction chain limit is mostly an artifact of a relatively unused feature heldover from artificially restricting block size, a feature called “Child Pays for Parent”.  According to research conducted by Tom Zander found [here](https://flowee.org/news/2020-07-cpfp-research/), there is very limited usage of CPfP on the BCH network.  In short, in his 3 months of monitoring network activity there were only 7 valid use cases where CPfP was used to lift the transaction above the 1-sat-per-byte.  This feature is not used in BCH yet still restricts the user experience and increases the complexity of development of wallets and applications built on top of Bitcoin Cash.

Issues with transaction chaining are exacerbated by the long block times periodically seen in Bitcoin Cash, the causes of which have been discussed elsewhere and were a major motivating factor in switching to the ASERT difficult adjustment algorithm.  Having a static transaction chaining limit while blocks somewhat frequently take over an hour (or even two hours) to be mined, results in a scenario where transactions could be significantly more at risk than normal.  Note, though, that even without these extenuating circumstances, this is always a risk with the proof of work system.

Given the motivations for implementing the transaction chaining limit are largely no longer relevant, the lack of sufficient tooling to allow SPV clients to account for it, and its poor interaction with the current semantics of transaction relaying, it appears that the transaction chaining limit provides little value while simultaneously increasing the difficulty of transacting on the Bitcoin Cash network.

**Personal Impacts**

During a Dublin Identity beta test with real users, an issue occurred causing sign-ups to periodically fail.  After investigation, it was identified that users’ transactions from the server used to fund SLP token transfers were not being accepted by the network due to the transaction chain limit being enforced. This problem has since been mitigated by the limit being increased to 50, along with some process changes.         

CoinFLEX uses SLP to distribute FLEX token dividends to its users.  The server distributes these dividends periodically, via chaining transactions.  These distributions were found to periodically fail due to reaching the unconfirmed transaction chaining limit.  CoinFLEX is mitigating this problem by using multiple UTXOs to spawn the chains, however their large user base and small limit of 50 transactions per UTXO, are causing disproportionate complexity within their system.  Raising the limit combined with increasing the base number of originating UTXOs helps to limit backend complexity.  Removing the limit would remove significant complexity for rejection edge-cases where a rejection was unable to be determined or was left unnoticed.

During Bitcoin Cash meetups it is not uncommon for users of the Bitcoin.com wallet to make more than 50 transactions within the timespan of a block, especially due to the encouraged behavior of brand-new users to transfer their BCH to other members of the meetup to “try it out”.  The user experience and “wow” factor of the technology is quickly doused when a new user’s transaction fails to send because their received UTXO is deeply chained.  Varying block times exacerbates this problem.

Software Verde has developed multiple applications that create and distribute transactions across the BCH network.  Managing multiple UTXO pools in order to handle appropriately scaling is doable but creates additional unwanted complexity.  While transactions will likely never completely be “fire and forget” on BCH, creating a balance with a larger buffer (i.e. supporting a longer chain limit) and having better available tools would allow us to produce applications more reliably and for less cost, facilitating the adoption of Bitcoin Cash to businesses and enterprises.


## Technical Description

The current policy limit of 50 unconfirmed ancestors or descendants, and the 101kb chain limit, is to be removed entirely once MTP >= 1621080000 and this limit removal remains in affect even in the case of a subsequent re-org to below that MTP.


## Security Considerations

Uncoordinated changes to mempool rules would likely result in a degradation of 0-conf transaction security.  0-conf transaction security is dependent on the network’s solution to circumventing double-spends. If nodes do not agree to enforce the same limits, merchants accepting transactions that have exceeded the unconfirmed transaction chaining limit would be at an increased risk of encountering and accepting a double-spend transaction.  

Example:  A malicious user submits a transaction exceeding the current chaining limit, knowing the merchant is connected to a node that does not enforce the limit. The node accepts this transaction as it is considered valid and the merchant believes they’ve received a payment from a valid 0-conf transaction. Due to its unconfirmed chain depth, for this transaction to propagate the node in question must wait to broadcast the transaction to its peers until after a new block has been found. During this time a malicious user could prepare a second transaction spending the same coin.  If submitted immediately after the new block has been found the two transactions will be in a race. Since the first transaction has not yet been broadcast to the rest of the network, there is an increased likelihood the second transaction could be seen by the majority of the network before the first transaction has had an opportunity to propagate. This situation is exacerbated if the node accepting the longer unconfirmed chain depth transaction does not also re-relay the transaction after a new block is mined that does not contain the transaction.


## Implementation Costs and Risks

From our research and discussions removal of the Unconfirmed Transaction Chain Limit does not present any apparent risks if conducted in a coordinated manner and presents zero risk of a network split. According to the research conducted by developer FreeTrader of BCHN, there is no apparent loss of performance in BCHN with the limit removed. However, if changes to the mempool rules are not coordinated by the different node implementations, 0-conf transaction facility and security will likely suffer. 

Costs associated with implementing this change are hard to encapsulate in this proposal.  At a minimum, this CHIP recognizes there is an operational burden that coordinated network upgrades place on node developers and users. Overall, this change will require a non-negligible amount of development time to implement, translating to a cost of labor, of which is bound to vary depending on the full-node implementation and route to resolution.

Additionally, the cost of investigating solutions for the unconfirmed transaction chaining limit have been significant for those who have undertaken the task. Based on an informal survey of BU and BCHN members, General Protocols has estimated approximately 500 engineering hours have been invested in development and general investigation of increasing the chained tx limit. This commitment of hours has been useful to understand the potential limitations bounding the limit from being completely removed.  After thorough investigation, no ill effect on performance has been found.


## Evaluation of Alternatives

If it is deemed necessary to keep the unconfirmed transaction chain limit in some capacity then a significantly larger increase to the limit would be a reasonable alternative.  

From our research, there isn’t a resource that becomes exhausted by a deep 0-conf chain. If there is indeed a technical limit, then we would advocate for node-developers to find what a responsible value is for that limit and suggest that here.

For the purposes of proposing an alternative solution: a 32MB block can hold approximately 135k transactions.  This limit could serve as a hypothetical starting point.  


## Stakeholders

Stakeholders relative to this proposal include: 

Full-node implementations
Node Developers
Wallet Developers
Bitcoin Cash related businesses.  

In our previous discussion we have engaged with several key stakeholders to understand their position on the requested change.

**Stakeholders Engaged in Discussion**

	  BCHN
	  Bitcoin Unlimited
	  Bitcoin Verde
	  General Protocols
	  Bitcoin.com
	  Coinflex
	  Flowee
  	  General Protocols

**Stakeholders Position Unknown**

    BCHD
    Knuth

## Stakeholders Statements

Jonathan Silverblood - Casual Wallet
>I believe that for money to be useful, it needs to be able to move at low cost and with ease. The current unconfirmed transaction chain limitation is effectively friction that makes Bitcoin Cash less useful as money, and I support a complete removal of the limit.

John Nieri - General Protocols
>GP supports the updated recommendations of this CHIP and commits any reasonable resources toward its realization. There is still room to expand security considerations and costs which are not trivial. Although this is a non-consensus CHIP, the expansion would make it an even better precedent for the high bar that we want to establish in the BCH ecosystem.

## CHIP Sponsors

**Software Verde** is a custom software development company based out of Columbus, Ohio, USA that has been in operation since 2011 and working within public and crypto sectors since early 2017.  Software Verde has extensive experience working with local governments to promote the adoption of blockchain technology and utilization of cryptocurrencies, and is the author and maintainer of the BCH Full Node, Bitcoin Verde.

**City of Dublin, OH** is a municipality of approximately 50k residents that has made an investment into the adoption of blockchain technology.  In turn, Dublin has built a blockchain-based digital identity management system utilizing BCH SLP tokens as a reward mechanism.  In late 2019, Dublin’s identity management project moved into a beta-testing phase where Software Verde was tasked with creating digital IDs for city employees and rewarding them with tokens for their participation.

**Bitcoin.com** is a provider of Bitcoin Cash related financial services and the owners of the Bitcoin.com wallet, one of Bitcoin Cash’s most popular non-custodial mobile friendly wallets.  Their website provides important services such as a cryptocurrency exchange, reporting network related news, and providing information to help influence the growth and adoption of Bitcoin Cash and Bitcoin Cash related businesses.

**CoinFLEX** is a popular cryptocurrency exchange service as well as the providers of the first Bitcoin Cash futures and lending exchange. CoinFLEX is the primary distributor of Flex Coins, an SLP token used to pay dividends to their users. Their business provides several unique financial services that attract cryptocurrency investors to the network, as well as foster a culture of professional trading within the Bitcoin Cash community.

## Timeline

This proposal is low risk and stands to provide high benefit to the network as a whole.  In addition, this request is a network-change only and therefore is not at risk of causing a chain split; however, uncoordinated changes to mempool rules by different full-nodes would likely result in a degradation of 0-conf transaction security. For these reasons, it is requested that this change be implemented in a coordinated manner on May 15th.

Choosing this date in particular is not significant in and of itself, although there seems to be no reason to deviate from history purely for the sake of it.

## License

To the extent possible under law, this work has waived all copyright and related or neighboring rights to this work under CC0.