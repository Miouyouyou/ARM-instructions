require 'set'

class Printer

  class << self

    @@parsed_instructions = Set.new
    @@strings = []
    def parse_only_kv(h)
      h.each do |k,v|
        case v
        when Hash
          parse_only_kv(v)
        else
          unless @@parsed_instructions.include? k
            @@strings << %Q|#{k.inspect}: #{v.inspect},\n|
            @@parsed_instructions.add(k)
          end
        end
      end
      @@strings.sort!
      @@strings.join
    end

  end
end

require 'json'
listing = JSON.parse(File.read("instruction_categorised_new_format.json"))

File.write("incomplete_alphabetical_listing.json", Printer.parse_only_kv(listing))

