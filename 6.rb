require 'rubygems'
require 'parslet'
require 'pp'

class Parser < Parslet::Parser
  rule(:lparen)       { space? >> str('(') >> space? }
  rule(:rparen)       { space? >> str(')') }
  rule(:lbracket)     { space? >> str('[') >> space? }
  rule(:rbracket)     { space? >> str(']') }
  
  rule(:space)        { match('\s').repeat(1) }
  rule(:space?)       { space.maybe }

  rule(:string)       { str('"') >> (str('\\') >> any | str('"').absnt? >> any
                                     ).repeat.as(:string) >> str('"') }
  rule(:identifier)   { match('[^\s\(\)\"\[\]]').repeat(1).as(:identifier) }
  rule(:number)       { match('[0-9]').repeat(1).as(:number) }

  rule(:atom)         { number | identifier | string | list | vector }
  rule(:expression)   { atom >> (space >> atom).repeat }
  rule(:list)         { lparen >> expression.as(:list) >> rparen }
  rule(:vector)       { lbracket >> expression.as(:vector) >> rbracket }
  rule(:program)      { list.repeat }

  root :program
end

# abstract
class SuckList
  attr_accessor :items

  def initialize(items)
    @items = items
  end
end

class FunCall < SuckList
end

class ArgList < SuckList
end

class Identifier
  attr_accessor :name

  def initialize(name)
    @name = name
  end
end

class Transform < Parslet::Transform
  rule(:number => simple(:number))         { number.to_i }
  rule(:string => simple(:string))         { string.to_s }
  rule(:identifier => simple(:identifier)) { Identifier.new(identifier.to_s) }
  rule(:list => subtree(:list))            { FunCall.new(list) }
  rule(:vector => sequence(:vector))       { ArgList.new(vector) }
end

parser = Parser.new
expression_tree = parser.parse(File.open(ARGV[0]))
ast = Transform.new.apply(expression_tree)
pp ast
