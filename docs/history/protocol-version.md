# Network Protocol Version History
| Version Number | Proposed In | Released | Summary |
|--|--|--|---|
|||Aug 2017| Bitcoin Cash hard fork.|
|70 015|[BIP-0152](/history/bips)|Jun 2017<BR>Bitcoin Core 0.14.2|Modified banning behaviour for invalid compact blocks.|
|70 012| [BIP-0130](/history/bips)|Nov 2016<BR>Bitcoin Core 0.12.0| Added `sendheaders` message.|
  |70 002|[BIP-0061](/history/bips)|Mar 2014<BR>Bitcoin Core 0.9.0| Added `reject` message.<BR>Send multiple `inv` messages in response to a `mempool` message if required (released but not in BIP).|
| 70 001 | [BIP-0037](/history/bips) | Feb 2013<br> Bitcoin Core 0.8.0 | Added `relay` flag to the `version` message.<br>Added `msg_filtered_block` inventory type to `getdata` message.<BR> Added `filterload`, `filteradd`, `filterclear` and `merkleblock` messages.<BR>Added `notfound` message (released but not in BIP).|
| 60 002 | [BIP-0035](/history/bips) | Sep 2012<br> Bitcoin Core 0.7.0| Added `mempool` message. Extended `getdata` message to allow download of memory pool transactions.|
| 60 001 | [BIP-0031](/history/bips) | May 2012<br> Bitcoin Core 0.6.1 |Added pong message. Added nonce field to `ping` message. |
| 60 000  | [BIP-0014](/history/bips) | Mar 2012<br> Bitcoin Core 0.6.0 |Network Version decoupled from Block Version.  User-agent replaced sub-version number. |
|||Sep 2011|BIP process implemented|
|31 800 | |Dec 2010<br> Bitcoin Core 0.3.15| Added `getheaders` message and `headers` message.|
|31 402|  | Oct 2010<br> Bitcoin Core 0.3.15| Time field added to `address` messages. |
| 311 ||Aug 2010<Br>Bitcoin Core 0.3.11| Added `alert` message.|
| 209 |  |May 2010<br>Bitcoin Core 0.2.9 | `address` message may accept a list of network addresses. Added checksum field to message headers.|
| 106 |  | Oct 2009<br> Bitcoin Core 0.1.6 | Added the following fields to the `version` message: `address-from`, `nonce`, `user-agent`, `current block height`. |