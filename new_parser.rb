
require 'pp'

class VariantsGenerator
  class << self
    def extract_variants_to_add_from_pattern(mnemonic_pattern)
      mnemonic_pattern.to_s.scan(/%\{(\w+)\}/).flatten.map(&:to_sym)
    end

    @@default_proc = ->(substitute_name, keys, all_infos) do
      returned_hash = {}
      # puts "-"*80
      # puts "[default_proc] name : #{substitute_name.inspect} - keys : #{keys.inspect}"
      # puts "-"*80
      substitute_infos = all_infos[:variants][substitute_name]
      if substitute_infos.nil?
        p substitute_name
        return
      end
      keys.each do |key|
        returned_hash[key.to_sym] = substitute_infos[key.to_sym]
      end
      returned_hash
    end
    @@special_variants = Hash.new {|h,k| @@default_proc}

    # Format :
    # {amode: {"": "default_description_key", "mnemonic_suffix": "description"}}
    @@special_variants[:amode] = ->(substitute_name, equivalences, all_infos) do
      returned_hash = {}
      substitute_infos = all_infos[:variants][:amode]
      if default_key = equivalences.delete(:"")
        returned_hash[:""] = substitute_infos[default_key.to_sym]
      end
      equivalences.to_a.flatten.each do |key|
        returned_hash[key.to_sym] = substitute_infos[key.to_sym]
      end
      returned_hash
    end

    # Format :
    # {vector_conversions: ["f32", "f64", "f16", "f32", ...]}
    # Array were used instead of Hash, since Hash can only have one unique key.
    # However, representing vector_conversions like this :
    # {vector_conversions: {"f32": ["f16", "f64", "i32"]}}
    @@special_variants[:vector_conversions] = ->(substitute_name, conversions, all_infos) do
      returned_hash = {}
      vtype_infos = all_infos[:variants][:dt]
      # Each conversion can be done in the opposite way
      conversions.each_slice(2) do |from, to|
        returned_hash[:"#{from}#{to}"] = "(from #{vtype_infos[from.to_sym]} to #{vtype_infos[to.to_sym]})"
        returned_hash[:"#{to}#{from}"] = "(from #{vtype_infos[to.to_sym]} to #{vtype_infos[from.to_sym]})"
      end
      returned_hash
    end

    # Format :
    # {operations: ["add", "sub"]}
    # In variants :
    # {operations: {"add": ["A", "Add"]}}
    @@special_variants[:operations] = ->(substitute_name, mnemonic_operations, all_infos) do
      returned_hash = {}
      operations_infos = all_infos[:variants][:operations]
      mnemonic_operations.each do |operation|
        mnemonic_part, description_part = operations_infos[operation.to_sym]
        returned_hash[mnemonic_part.to_sym] = description_part
      end
      returned_hash
    end

    def get_variants_for(base_mnemonic_pattern, special_variants, flags, all_infos)
      variants_obtained = {}
      variant_infos = all_infos[:variants]
      flags_infos = all_infos[:flags]
      extract_variants_to_add_from_pattern(base_mnemonic_pattern).each do |variant|
        variants_obtained[variant] = variant_infos[variant]
      end
      flag_infos = all_infos[:flags]
      flags.each do |flag|
        if replacements = flag_infos[flag]
          # p replacements
          replacements.each do |variant, infos|
            variants_obtained[variant] = infos
          end
        end
      end
      special_variants.each do |variant, infos|
        h = @@special_variants[variant][variant, infos, all_infos]
        variants_obtained[variant] = h
      end
      # pp variants_obtained
      variants_obtained
    end

    # pp generate_variants("vabs%{c}.%{vtype}", "Vector Absolute %{vtype} %{c}",  {vtype: [:f32, :f64]}, [:simd_conditions], $infos)
    def generate_variants(base_mnemonic_pattern, base_description_pattern, variants, flags, all_infos)

      generated_variants = {base_mnemonic_pattern => base_description_pattern}

      fake_substitutor = Proc.new {|h,k| "%{#{k}}"}

      mnemonic_substitutes = get_variants_for(base_mnemonic_pattern, variants, flags, all_infos)
      mnemonic_substitutor = Hash.new(&fake_substitutor)
      description_substitutor = Hash.new(&fake_substitutor)

      mnemonic_substitutes.each do |substitute, current_substitution_infos|
        incomplete_variants = generated_variants.clone
        generated_variants.clear
        incomplete_variants.each do |mnemonic_pattern, description_pattern|
          current_substitution_infos.each do |mnemonic_part, description_part|
            mnemonic_substitutor[substitute] = mnemonic_part
            description_substitutor[substitute] = description_part
            generated_variants[(mnemonic_pattern.to_s % mnemonic_substitutor)] = ((description_pattern % description_substitutor).gsub(/\s+/, " ").strip)
          end
        end
      end
      generated_variants
    end
  end
end

require 'json'
all_instructions = JSON.parse(File.read("incomplete_alphabetical_listing.json"), {symbolize_names: true}).freeze
super_list = {
  "substitutions": {
    "variants": all_instructions[:variants],
    "flags": all_instructions[:flags]
  },
  "instructions": {}
}
all_instructions[:ARM].each do |base_mnemonic_pattern, infos|
  super_list[:"instructions"][base_mnemonic_pattern] = {
    "description" => infos[0],
    "variants" => VariantsGenerator.generate_variants(base_mnemonic_pattern, infos[0], infos[1], infos[2], all_instructions)
  }
end
puts JSON.generate(super_list, {object_nl: "\n", array_nl: "\n", indent: "  ", space: " "})
