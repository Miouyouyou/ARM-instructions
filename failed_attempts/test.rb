class Description
  attr_reader :op, :op1, :op2, :description, :mnemonic, :variant
  def initialize(op, op1, op2, *description)
    @op = op
    @op1 = (op1 != "-" ? op1 : 0)
    @op2 = (op2 != "-" ? op2 : 0)
    mnemonic_index = mnemonic_index(description)
    variant_index = variant_index(description)
    @description = description[0...mnemonic_index].join(" ")
    @mnemonic = description[mnemonic_index]
    @variant = description[variant_index] if variant_index
  end
  def self.is_upcase_word(word)
    word =~ /^[A-Z]+$/
  end
  def self.is_between_parentheses(sentence)
    sentence =~ /^\(.*$/
  end
  @@last_upcase_word_proc = method(:is_upcase_word)
  @@last_word_in_parentheses = method(:is_between_parentheses)
  def last_upcase_word_index(arr)
    arr.rindex(&@@last_upcase_word_proc)
  end
  alias :mnemonic_index :last_upcase_word_index
  def last_word_in_parantheses(arr)
    arr.rindex(&@@last_word_in_parentheses)
  end
  alias :variant_index :last_word_in_parantheses

  def to_s
    shown_values = []
    [:op, :op1, :op2, :description, :mnemonic].each do |component|
      shown_values << (self.send(component) || 0)
    end
    "op:%05d op1:%02d op2:%05d definition:%s mnemonic:%s" % shown_values
  end
end

cl = File.read("test.txt").lines
content = cl[1..-1].map(&:split)
definitions = content.map {|line| p line; Description.new(*line)}.group_by {|x| x.op}
definitions.each do |group, definition|
  if definition.any?(&:op1)
    new_def = definition.group_by(&:op1)
    definitions[group] = new_def
    new_def.each do |sub_group, sub_def|
      if sub_def.any?(&:op2)
        new_def[sub_group] = sub_def.group_by(&:op2)
      end
    end
  end
end

p definitions


def print_definitions(group, defs)
  print_defs = method(:print_definitions)
  case defs
  when Array then defs.each do |d| puts d end
  when Hash then defs.each(&print_defs)
  end
end

definitions.each(&(method(:print_definitions)))
