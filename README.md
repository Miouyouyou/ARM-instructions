This project currently provides all the variants of several ARM assembly mnemonics, with descriptions of these mnemonics and variants.

The final goal is to provide :
- all the keywords and mnemonics described in the official ARM architecture manuals;
- all the encodings of each instruction, as described in the same manuals;
in formats that can easily be interpreted by programs.

Currently : 
- the only available format is JSON. XML will be next.
- the most advanced list is [almost_complete_list.json](./almost_complete_list.json)
- almost_complete_list.json is generated with the following command : 

  ruby new_parser.rb > almost_complete_list.json

The current main point is to be able to generate configuration files for syntax highlighters tools like Rouge, in order to highlight ARM assembly scripts presented on webpages.

[![Money !](https://pledgie.com/campaigns/32702.png?skin_name=chrome)](https://pledgie.com/campaigns/32702)

BTC : 16zwQUkG29D49G6C7pzch18HjfJqMXFNrW

