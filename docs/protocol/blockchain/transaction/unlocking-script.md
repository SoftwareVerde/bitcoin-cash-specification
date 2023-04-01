# Unlocking Script

An unlocking script is a [Script](/protocol/blockchain/script) that is used to prove that a transaction is permitted to spend a given UTXO.
This is accomplished by first executing the unlocking script and then executing the [locking script](/protocol/blockchain/transaction/locking-script) for the UTXO referenced by the transaction input.
If this execution triggers no failures and leaves a single non-zero (TRUE) value on the stack, the UTXO has been successfully unlocked.
One way to look at this is that the unlocking script provides an initial state that acts as an inverse to the previously published locking script.

For more information about how script execution works, see [Script](/protocol/blockchain/script).  For information on how signatures (which typically go in the unlocking script) are generated, see [Transaction Signatures](/protocol/blockchain/transaction/transaction-signing).
