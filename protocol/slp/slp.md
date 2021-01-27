# Simple Ledger Protocol

Simple Ledger Protocol is a token system for the Bitcoin Cash network.
It allows users to create, issue, and transfer digital tokens that enjoy the same security model and network of Bitcoin Cash.
Users can associate the created tokens with assets and values, and thus, utilize the [Blockchain](/protocol/blockchain) as the public ledger to achieve transparency and integrity for their transactions.


## The intent of token systems

The Blockchain provides an open ledger with transparency and integrity to document transactions.
However, to utilize this ledger, one has to devise rules and security models for the transactions, as well as the computational power to support a network that complies with the rules.
The above costs make such applications prohibitively expensive for most individual users, while also hindering the emergence of coins for specific applications and transactions.
Such needs drive the creation of various token systems on Bitcoin Cash.
Token systems are additional layers of protocols on Bitcoin Cash, that allow the creation, issuance, and transfer of tokens on the Bitcoin Cash network.
Users and creators of the tokens can utilize the computational power and other benefits of the Bitcoin Cash network for their own token transactions.


## The design of Simple Ledger Protocol

Simple Ledger Protocol (SLP) is one of the most prevalent token systems on Bitcoin Cash.
SLP employs a “colored coins” design that associates token amounts with BCH [transaction](/protocol/blockchain/transaction) outputs.
An SLP transaction will utilize a [data output](/protocol/blockchain/transaction/locking-script#data-output) to include a message in one of four predefined formats to annotate the SLP transaction information associated with each transaction output in the same transaction.
The predefined formats include: [GENESIS](/protocol/slp/genesis), [MINT](protocol/slp/mint), [SEND](/protocol/slp/send), and [COMMIT](/protocol/slp/commit).
The GENESIS message defines the SLP token and issues the first batch of tokens.
The MINT message issues further batches of tokens.
The SEND message denotes the number of tokens sent to each output.
The COMMIT message is proposed to allow periodical commits of all transaction hashes on the token.


## Consensus rules

In all cases of SLP transactions, there must be an [output script](/protocol/blockchain/transaction/locking-script#data-output) that begins with OP_RETURN (opcode 0x6a) within the first output (vout=0).
The data output should be an SLP message that conforms to the predefined format.


For transfer transactions (SEND), the sum of token outputs specified OP_RETURN may not exceed the sum of valid token inputs.
Valid token inputs are transaction inputs where the previous transactions are known to conform to SLP consensus rules.
The values of valid token inputs are as listed in SLP messages of the transactions that create the transaction outputs.
Inputs of differing token types or token IDs are ignored.

For issuance transactions (GENESIS/MINT), Genesis transactions are self-evidently valid or invalid, and MINT transactions require the baton input for the token being issued.
The baton is either directly from the Genesis transaction that created it, or indirectly via the previous Mint transaction.
Inputs of differing token types or token IDs are ignored.
Token inputs are also ignored.


## Validation of the SLP transactions

The “colored coins” design ensures that any transaction that attempts to double-spend SLP token outputs will also double-spend the BCH outputs, and thus, will be rejected by the network.
However, invalid SLP token transactions will be accepted by the network and included in the Blockchain if they are contained within valid BCH transactions.
Therefore, validation of an SLP transaction requires a directed acyclic graph (DAG), with transactions as its vertices and transaction inputs as its edges, that originates from the transaction that is being validated and terminates at the Mint or Genesis transaction.
Full nodes can construct the DAG proof for an SLP transaction by recursively iterating through the inputs of the said transaction to trace their ancestor transactions.


Several optimizations have been made to this process.
Vertices of transactions that provide zero tokens can be pruned, so are the input edges of known valid transactions.
Otherwise, DAG proof for SLP transactions can be cached to accelerate the proof of future SLP transactions if pruning is not employed.
The process can also stop before the full DAG is constructed when the sum of proved valid inputs exceeds the output sum, or when the sum of possibly valid inputs goes below the output sum.

Without DAG proofs, other validation methods are also available.
Users can trust SLP transactions with incomplete DAG proofs.
However, such proofs can be exploited since an attacker can "bury" their invalid transaction by forging another transaction that seems to be valid by itself and spend the output of the invalid transaction.
This process can be repeatedly applied, resulting in a chain of transactions on top of the invalid transaction.
In such cases, the incomplete DAG may only capture the seemingly valid chain of transactions and thus, may produce a false proof.
Users can also rely on third-party API or block explorer for validation.
If checkpoints are available for the token, users can also use DAG proofs that terminate at transactions included the checkpoints to validate transactions of the said token.


## Advantages and disadvantages of SLP 

SLP is non-invasive, such that it does not make any change to Bitcoin Cash protocols.
Therefore, transactions that carry SLP tokens can be accepted and validated in the same way as typical BCH transactions by the network.
Meanwhile, the “colored coins” design allows SLP tokens to utilize the same security model of BCH since any attempts to double-spend SLP tokens will also double-spend the associated BCH transaction outputs, which will be rejected by the network.
However, since tokens are considered spent once their associated output is spent, token inputs of valid BCH transactions will always be spent, even if the token transactions within the messages are invalid or no token transaction is included.
Therefore, there is a risk that if wallet applications are not aware of the SLP tokens associated with certain BCH UTXOs or submitted invalid SLP transactions, due to bugs or unexpected errors, users may lose their SLP tokens with no possible remedies.
Also due to the “colored coins” design, SLP transactions must still obey the consensus rules of BCH transactions.
Therefore, outputs with SLP tokens would need to be above the dust threshold, and if the total BCH satoshis of the inputs with SLP tokens cannot afford the satoshis of the outputs, additional BCH satoshis input must be included.
Thus, users of SLP tokens may have to possess BCH satoshis in addition to the “colored coins” to facilitate their SLP transactions.
Such inconvenience, however, may be resolved through Postage services.
