Use
---

This project currently provides all the variants of several ARM assembly mnemonics, with descriptions of these mnemonics and variants.

Goals
-----

The final goal is to provide :
* all the keywords and mnemonics described in the official ARM architecture manuals;
* all the encodings of each instruction, as described in the same manuals;
in formats that can easily be interpreted by programs.

Current state
-------------

Currently : 
* the only available formats are JSON and YAML. XML will be next.
* the most advanced list is [almost_complete_list.json](./almost_complete_list.json)
* almost_complete_list.json is generated with the following command : 

`ruby new_parser.rb > almost_complete_list.json`

* [new_parsed.rb](./new_parsed.rb) uses [incomplete_alphabetical_listing.json](./incomplete_alphabetical_listing.json) to generate this list.

The current main point is to be able to generate configuration files for syntax highlighters softwares like [Rouge](http://rouge.jneen.net/), in order to highlight ARM assembly scripts presented on webpages.

Tipping
-------

[Pledgie !](https://pledgie.com/campaigns/32702)

BTC: 16zwQUkG29D49G6C7pzch18HjfJqMXFNrW

[![Tip with Altcoins](https://shapeshift.io/images/shifty/small_light_altcoins.png)](https://shapeshift.io/shifty.html?destination=16zwQUkG29D49G6C7pzch18HjfJqMXFNrW&output=BTC)

