<!-- TITLE: Transaction -->
<!-- SUBTITLE: means of transfer -->

A transaction is how transfers are made in the blockchain.  It comprises of a set of input [UTXOs](/glossary/UTXO) which will be spent to a set of output [UTXOs](/glossary/UTXO).  The blockchain mining and full node software ensures that every transaction follows the blockchain's rules before admitting the transaction into a block.  Verification of a transaction ensures that the input UTXOs have not already been spent, that quantity of input coins is greater than or equal to the quantity of output coins (any extra is given to the miner as a transaction fee), and that the transaction satisifies all spending constraints specified by the UTXO's constraint scripts.