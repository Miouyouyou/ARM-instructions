require 'set'
require 'pp'

class ListParser
  class << self

    @@infos = {
      conditions: {
        variants: {
          "": "",
          EQ: "(If APSR.Z == 1 [Equal])",
          NE: "(If APSR.Z == 0 [Not Equal])",
          CS: "(If APSR.C == 1 [Carry Set])",
          CC: "(If APSR.C == 0 [Carry Clear])",
          MI: "(If APSR.N == 1 [Minus])",
          PL: "(If APSR.N == 0 [Plus])",
          VS: "(If APSR.V == 1 [Overflow])",
          VC: "(If APSR.V == 0 [No Overflow])",
          HI: "(If APSR.C == 1 AND APSR.Z == 0 [Unsigned Higher])",
          LS: "(If APSR.C == 0 OR APSR.Z == 1 [Unsigned Lower])",
          GE: "(If APSR.N == APSR.V [Signed Greater or Equal])",
          LT: "(If APSR.N != APSR.V [Signed Lesser Than])",
          GT: "(If APSR.N == APSR.V AND APSR.Z == 0 [Signed Greater Than])",
          LE: "(If APSR.N != APSR.V OR APSR.Z != 0 [Signed Lesser or Equal])",
          AL: "(Always)"
        },
      },
      flag_updater: {
        variants: {
          :"" => "",
          S: "(Update APSR flags)"
        }
      },
      coprocessor_encodings: {
        variants: {
          :"" => "",
          :"2" => "(Alternative encoding)"
        }
      },
      thumb_only: {
        variants: {
          :"" => "(Thumb instruction)"
        }
      },
      two_half_parts: {
        before: [[:remove_current_suffix, :BB]],
        variants: {
          BB: "(Bottom half with Bottom half)",
          BT: "(Bottom half with Top half)",
          TB: "(Top half with Bottom half)",
          TT: "(Top half with Top half)"
        }
      },
      last_half_parts: {
        before: [[:remove_current_suffix, :B]],
        variants: {
          B: "(x Bottom half)",
          T: "(x Top half)"
        }
      },
      cross_parts: {
        variants: {
          "" => "(Bottom x Bottom - Top x Top)",
          X: "(Bottom x Top - Top x Bottom)"
        }
      },
      rounded: {
        variants: {
          "" => "(result truncated)",
          R: "(result Rounded)"
        }
      },
      half_and_half: {
        variants: {
          BT: "Bottom half with Top half",
          TB: "Top half with Bottom half"
        }
      },
      deprecated: {
        variants: {
          :"" => "(Deprecated)"
        }
      },
      byte_suffix: {
        variants: {
          :"" => "",
          B: "Byte"
        }
      },
      stc_l_encoding: {
        variants: {
          :"" => "",
          L: "(D == 1 encoding)" # ??? The manual is quite vague about this
        }
      },
      amode: {
        variants: {
          da: "Decrement After",
          db: "Decrement Before",
          fa: "Full Ascending",
          fd: "Full Descending",
          ea: "Empty Ascending",
          ed: "Empty Descending",
          ia: "Increment After",
          ib: "Increment Before",
        }
      },
      vector_sizes: {
        variants: {
          8 => "(8 bits components)",
          16 => "(16 bits components)",
          32 => "(32 bits components)",
          64 => "(64 bits components)"
        }
      },
      vector_types: {
        variants: {
          :"8" => "(8 bits components)",
          :"16" => "(16 bits components)",
          :"32" => "(32 bits components)",
          s8: "(Signed Integer 8 bits components)",
          s16: "(Signed Integer 16 bits components)",
          s32: "(Signed Integer 32 bits components)",
          s64: "(Signed Integer 64 bits components)",
          u8: "(Unsigned Integer 8 bits components)",
          u16: "(Unsigned Integer 16 bits components)",
          u32: "(Unsigned Integer 32 bits components)",
          u64: "(Unsigned Integer 64 bits components)",
          i8: "(Integer 8 bits components)",
          i16: "(Integer 16 bits components)",
          i32: "(Integer 32 bits components)",
          i64: "(Integer 64 bits components)",
          f16: "(16 bits Float components)",
          f32: "(32 bits Float components)",
          f64: "(64 bits Float components)"
        }
      },
      comparaisons: {
        variants: {
          gt: "Greater than",
          ge: "Greater or equal",
          eq: "Equal",
          le: "Lesser or equal",
          lt: "Lesser than"
        }
      },
      operations: {
        variants: {
          accumulate: "Accumulate",
          accumulate_long: "Accumulate Long",
          subtract: "Subtract",
          subtract_long: "Subtract Long",
          min: "Minimum",
          max: "Maximum",
          exception: "(Generate Exceptions)"
        }
      }

    }

    def generate_variants(mnemonics, variant_informations)
      generated_variants = {}

      mnemonics.each do |mnemonic, fullname|

        to_do_before = variant_informations[:before]
        if to_do_before
          to_do_before.each do |meth, *args|
            mnemonic, fullname = self.send(meth, mnemonic, fullname, *args)
          end
        end

        variant_informations[:variants].each do |suffix, precision|
          generated_variants[:"#{mnemonic}#{suffix}"] = "#{fullname} #{precision}"
        end

      end

      generated_variants
    end

    @@common_variants = {
      conditions: [:unconditionnal, :simd_conditions],
      suffixes: [:arm_only]
    }
    def add_common_variants_to(variants_informations)
      @@common_variants.each do |common_variant, counterindications|
        if (variants_informations & counterindications).empty?
          variants_informations.push(common_variant)
        end
      end
      variants_informations
    end

    def parse_instruction_definition(mnemonic, infos)
      fullname, *mnemonic_variants = infos

      add_common_variants_to(mnemonic_variants)

      derived_mnemonics = {mnemonic => fullname}
      pp derived_mnemonics
      mnemonic_variants.each do |variant|
        variant_informations = @@infos[variant]
        if variant_informations
          derived_mnemonics.replace(
            generate_variants(derived_mnemonics, variant_informations)
          )
        end
      end

      return derived_mnemonics
    end

    def parse_instructions(instructions_list)
      mnemonics = {}
      instructions_list.each do |mnemonic, infos|
        mnemonics.merge!(parse_instruction_definition(mnemonic, infos))
      end
      mnemonics
    end

    def parse_category(hashed_list, previous_categories=[], indent=0, mnemonics={})
      case hashed_list.values.first
      when Hash
        hashed_list.each do |category, sub_list|
          parse_category(sub_list, previous_categories + [category], indent+1, mnemonics)
        end
      when Array
        mnemonics.merge!(parse_instructions(hashed_list))
      end
      mnemonics
    end

    # @@simple_variants = Set.new
    # @@complex_variants = {}
    # def enumerate_variants(variants_infos)
    #   variant_infos.each do |variant|
    #     case variant
    #     when Symbol, String
    #       @@simple_variants.add(variant)
    #     when Hash
    #       variant.each do |variant_name, sub_variants|
    #         @@complex_variants[variant_name] ||= Set.new
    #         sub_variants.to_a.each do |sub_variant|
    #           @@complex_variants[variant_name].add(sub_variant)
    #         end
    #       end
    #     else
    #       puts "[parse_instruction_definition] Unknown class #{variant.class}"
    #     end
    #   end
    # end

    def print_found_variants
      puts "Simple variants : #{@@simple_variants.inspect}"
      puts "Complex variants: "
      pp @@complex_variants
    end



    def remove_current_suffix(mnemonic, fullname, suffix_to_remove)
      [mnemonic.to_s.sub(/#{suffix_to_remove}$/, '').to_sym, fullname]
    end

    def append_to_fullname(fullname, precision)
      fullname << " " << precision
    end

    def generated_mnemonic_to_string(mnemonic_infos)
      "#{mnemonic_infos.first}: #{mnemonic_infos.last}"
    end

  end
end

load 'first_list.rb'
pp ListParser.parse_category(ARM)
