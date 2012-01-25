require 'rubygems'
require 'parslet'
require 'pp'

class Parser < Parslet::Parser
  rule(:lparen)       { space? >> str('(') >> space? }
  rule(:rparen)       { space? >> str(')') }
  
  rule(:space)        { match('\s').repeat(1) }
  rule(:space?)       { space.maybe }

  rule(:string)       { str('"') >> (str('\\') >> any | str('"').absnt? >> any
                                     ).repeat.as(:string) >> str('"') }
  rule(:identifier)   { match('[^\s\(\)\"]').repeat(1).as(:identifier) }
  rule(:number)       { match('[0-9]').repeat(1).as(:number) }

  rule(:atom)         { number | identifier | list | string }
  rule(:expression)   { atom >> (space >> atom).repeat }
  rule(:list)         { lparen >> expression.as(:list) >> rparen }
  rule(:program)      { list.repeat }

  root :program
end

parser = Parser.new
pp parser.parse(File.open(ARGV[0]))

