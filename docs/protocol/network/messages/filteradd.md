<div class="cwikmeta">{
"title":"FILTERADD",
"related":["/protocol","/protocol/p2p/getdata","/protocol/p2p/filterload","/protocol/p2p/filterclear"]
}</div>

# Request: Filter Add (“filteradd”)

Add an entry into the installed bloom filter.

## Message Format

| Field | Length | Format | Description |
|--|--|--|--|
| data length | variable | [variable length integer](/protocol/formats/variable-length-integer) | The size of the piece of the data to be added to the bloom filter. |
| data | `data_length` bytes | bytes | The raw data of the object to the be added. |

*data* is inserted into the bloom filter, exactly as if the [insert](https://github.com/BitcoinUnlimited/BitcoinUnlimited/blob/eb264e627e231f7219e60eef41b4e37cc52d6d9d/src/bloom.cpp#L116) operation had been called locally before sending the filter.
