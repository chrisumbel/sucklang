require 'rubygems'
require 'parslet'
require 'pp'
require 'java'
require 'bitescript'
import java.lang.System
import java.io.PrintStream

include BiteScript

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

class Transform < Parslet::Transform
  rule(:number => simple(:number))         { number.to_i }
  rule(:string => simple(:string))         { string.to_s }
  rule(:identifier => simple(:identifier)) { Identifier.new(identifier.to_s) }
  rule(:list => subtree(:list))            { FunCall.new(list) }
  rule(:vector => sequence(:vector))       { ArgList.new(vector) }
end

class SuckList
  attr_accessor :items

  def initialize(items)
    @items = items
  end

  def emit(klass, method, args)
  end
end

class FunCall < SuckList  
  def emit(klass, method, args = [])
    @items.each do |item|
      item.emit(klass, method, args)
    end
  end
end

class ArgList < SuckList
end

class Identifier
  attr_accessor :name

  def initialize(name)
    @name = name
  end

  def emit(klass, method, args)
  end
end

module Emittable
  def emit(klass, method, args)
    method.ldc self
    self
  end
end

class Fixnum
  include Emittable
end

class String
  include Emittable
end

def compile(ast, class_name)
  fb = FileBuilder.build(__FILE__) do
    public_class class_name do 
      public_static_method "main", [], void, string[] do |main|
        ast.each do |statement| 
          statement.emit(this, main)
        end
        
        main.returnvoid
      end
    end
  end
  
  fb.generate do |filename, class_builder|
    File.open(filename, 'w') do |file|
      file.write(class_builder.generate)
    end
  end
end

parser = Parser.new
expression_tree = parser.parse(File.open(ARGV[0]))
ast = Transform.new.apply(expression_tree)

file_name = ARGV[0]
class_name = File.basename(file_name, File.extname(file_name))
compile ast, class_name
