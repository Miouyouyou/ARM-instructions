
class Reprinter
  class << self
    @@stringify_symbols = Hash.new {|h,k| Proc.new {|e| e}}
    @@stringify_symbols[Hash] = Proc.new {|h|
      h_clone = h.clone
      h.clear
      h_clone.each do |k,v|
        parsed_k = k.is_a?(Symbol) ? k.to_s : k
        h[parsed_k] = @@stringify_symbols[v.class][v]
      end
      h
    }
    @@stringify_symbols[Array] = Proc.new {|a|
      a.map {|e| @@stringify_symbols[e.class][e]}
    }
    @@stringify_symbols[Symbol] = Proc.new {|s| s.to_s}

    def reprint_instruction(mnemonic, description, variants)
      mnemonic_template = mnemonic.to_s
      description_template = description.to_s

      flags = variants.select {|variant| variant.is_a? Symbol}.map(&:to_s)
      remaining_variants = (variants - flags)[0]
      real_variants = @@stringify_symbols[remaining_variants.class][remaining_variants]

      if variants.include?(:operations)
        mnemonic_template << "%{op}"
        description_template << " %{op}"
      end

      if (flags & [:unconditionnal, :simd_conditions]).empty?
        mnemonic_template << "%{cond}"
        description_template << " %{cond}"
      end
      if flags.include?(:simd_conditions)
        mnemonic_template << ".%{vtype}"
        description_template << " %{vtype}"
      end

      [mnemonic_template, description_template, real_variants, flags]
    end

    def parse_categories(cat)

      new_listing = {}
      cat.each do |subcat, infos|
       case infos
       when Hash
        new_listing[subcat] = parse_categories(infos).clone
       when Array
        description, *variants = infos
        mnemonic, *mnemonic_infos = reprint_instruction(subcat, description, variants)
        p mnemonic
        new_listing.delete(subcat)
        new_listing[mnemonic] = mnemonic_infos
       end
      end
      new_listing
    end

    def categories_to_string(cat, cat_name, indent=0)
      content_string = %Q|#{" "*indent}"#{cat_name}": {\n|
      cat.each do |subcat, infos|
        case infos
        when Hash
          content_string << categories_to_string(infos, subcat, indent+2) << ",\n"
        when Array
          content_string << %Q|#{" "*(indent+2)}#{subcat.inspect}: #{infos.inspect},\n|
        end
      end
      content_string << %Q|#{" "*indent}}|
      content_string
    end
  end
end

load 'first_list.rb'
require 'pp'


new_categories = Reprinter.parse_categories(ARM)
File.write("instruction_categorised_new_format.json", Reprinter.categories_to_string(new_categories, "ARM").gsub("=>", ":").gsub(" nil", " null"))
# require 'yaml'
# puts new_categories.to_yaml
