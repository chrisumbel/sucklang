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

  def emit(klass, method, params)
  end
end

class FunCall < SuckList
  def op_add(klass, method, args)
    i = 0
    retval = 0

    @params.each do |param|
      i += 1

      case param
      when Identifier
        retval = method.iload args.index(param.name)
      else
        retval = param.emit(klass, method, args)
      end

      method.iadd if i > 1
    end

    retval
  end

  def op_defun(klass, method, args)
    java_args = []
    args = @params[1].items.map {|item| 
      java_args << klass.int
      item.name 
    }

    klass.public_static_method @params[0].name, [], klass.int, *java_args do |method|
      @params[1..-1].each do |item|
       item.emit(klass, method, args)
      end

      method.ireturn
    end
  end

  def op_println(klass, method, args)
    retval = nil

    @params.each do |param|
      method.getstatic System, :out, PrintStream
      retval = param.emit(klass, method, args)

      type = case retval
             when Fixnum
               method.int
             else
               method.object
             end
      
      method.invokevirtual PrintStream, "print", [method.void, type]
    end
    
    method.getstatic System, :out, PrintStream
    method.invokevirtual PrintStream, "println", [method.void]
    retval
  end

  def op_funcall(klass, method, args) 
    java_params = [klass.int]

    @params.each do |param|
      method.ldc param
      java_params << klass.int
    end

    method.invokestatic klass, @name, java_params
  end

  def emit(klass, method, args = [])
    result = nil

    case @name
    when 'defun'
      result = op_defun(klass, method, args)
    when '+'
      result = op_add(klass, method, args)
    when 'println'
      result = op_println(klass, method, args)
    else
      result = op_funcall(klass, method, args)
    end

    result
  end

  def initialize(items)
    super(items)
    @name = items[0].name
    @params = items[1..-1]
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
