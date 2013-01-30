require "location"

module Crystal
  # Base class for nodes in the grammar.
  class ASTNode
    def location
      @location
    end

    def location=(location)
      @location = location.clone
    end
  end

  # A container for one or many expressions.
  class Expressions < ASTNode
    attr_accessor :expressions

    def self.from(obj : Nil)
      nil
    end

    def self.from(obj : Array)
      case obj.length
      when 0
        nil
      when 1
        obj.first
      else
        new obj
      end
    end

    def self.from(obj)
      obj
    end

    def initialize(expressions = [])
      @expressions = expressions
    end

    def ==(other : self)
      other.expressions == expressions
    end

    def empty?
      @expressions.empty?
    end

    def last
      @expressions.last
    end

    def accept_children(visitor)
      @expressions.each { |exp| exp.accept visitor }
    end
  end

  # The nil literal.
  #
  #     'nil'
  #
  class NilLiteral < ASTNode
    def ==(other : self)
      true
    end
  end

  # A bool literal.
  #
  #     'true' | 'false'
  #
  class BoolLiteral < ASTNode
    attr_accessor :value

    def initialize(value)
      @value = value
    end

    def ==(other : self)
      other.value == value
    end
  end

  class NumberLiteral < ASTNode
    attr_accessor :value
    attr_accessor :has_sign

    def initialize(value)
      @has_sign = value[0] == '+' || value[0] == '-'
      @value = value
    end
  end

  # An integer literal.
  #
  #     \d+
  #
  class IntLiteral < NumberLiteral
    def ==(other : self)
      other.value.to_i == value.to_i
    end
  end

  # A long literal.
  #
  #     \d+L
  #
  class LongLiteral < NumberLiteral
    def ==(other : self)
      other.value.to_i == value.to_i
    end
  end

  # A float literal.
  #
  #     \d+.\d+f
  #
  class FloatLiteral < NumberLiteral
    def ==(other : self)
      other.value.to_f == value.to_f
    end
  end

  # A double literal.
  #
  #     \d+.\d+f
  #
  class DoubleLiteral < NumberLiteral
    def ==(other : self)
      other.value.to_d == value.to_d
    end
  end

  # A char literal.
  #
  #     "'" \w "'"
  #
  class CharLiteral < ASTNode
    attr_accessor :value

    def initialize(value)
      @value = value
    end

    def ==(other : self)
      other.value == value
    end
  end

  class StringLiteral < ASTNode
    attr_accessor :value

    def initialize(value)
      @value = value
    end

    def ==(other : self)
      other.value == value
    end
  end

  class SymbolLiteral < ASTNode
    attr_accessor :value

    def initialize(value)
      @value = value
    end

    def ==(other : self)
      other.value == value
    end
  end

  # An array literal.
  #
  #  '[' ( expression ( ',' expression )* ) ']'
  #
  class ArrayLiteral < ASTNode
    attr_accessor :elements

    def initialize(elements = [])
      @elements = elements
    end

    def ==(other : self)
      other.elements == elements
    end
  end

  # A method call.
  #
  #     [ obj '.' ] name '(' ')' [ block ]
  #   |
  #     [ obj '.' ] name '(' arg [ ',' arg ]* ')' [ block]
  #   |
  #     [ obj '.' ] name arg [ ',' arg ]* [ block ]
  #   |
  #     arg name arg
  #
  # The last syntax is for infix operators, and name will be
  # the symbol of that operator instead of a string.
  #
  class Call < ASTNode
    attr_accessor :obj
    attr_accessor :name
    attr_accessor :args
    attr_accessor :block

    attr_accessor :name_column_number
    attr_accessor :has_parenthesis
    attr_accessor :name_length

    def initialize(obj, name, args = [], block = nil, name_column_number = nil, has_parenthesis = false)
      @obj = obj
      @name = name
      @args = args
      @block = block
      @name_column_number = name_column_number
      @has_parenthesis = has_parenthesis
    end

    def ==(other : self)
      other.obj == obj && other.name == name && other.args == args && other.block == block
    end

    # def name_column_number
    #   @name_column_number || column_number
    # end

    # def name_length
    #   @name_length ||= name.to_s.ends_with?('=') || name.to_s.ends_with?('@') ? name.length - 1 : name.length
    # end
  end

  # An if expression.
  #
  #     'if' cond
  #       then
  #     [
  #     'else'
  #       else
  #     ]
  #     'end'
  #
  # An if elsif end is parsed as an If whose
  # else is another If.
  class If < ASTNode
    attr_accessor :cond
    attr_accessor :then
    attr_accessor :else

    def initialize(cond, a_then = nil, a_else = nil)
      @cond = cond
      @then = Expressions.from a_then
      @else = Expressions.from a_else
    end

    def accept_children(visitor)
      self.cond.accept visitor
      self.then.accept visitor if self.then
      self.else.accept visitor if self.else
    end

    def ==(other : self)
      other.cond == cond && other.then == self.then && other.else == self.else
    end
  end

  # Assign expression.
  #
  #     target '=' value
  #
  class Assign < ASTNode
    attr_accessor :target
    attr_accessor :value

    def initialize(target, value)
      @target = target
      @value = value
    end

    def ==(other : self)
      other.target == target && other.value == value
    end
  end

  # Assign expression.
  #
  #     target [',' target]+ '=' value [',' value]*
  #
  class MultiAssign < ASTNode
    attr_accessor :targets
    attr_accessor :values

    def initialize(targets, values)
      @targets = targets
      @values = values
    end

    def accept_children(visitor)
      @targets.each { |target| target.accept visitor }
      @values.each { |value| value.accept visitor }
    end

    def ==(other : self)
      other.targets == targets && other.values == values
    end
  end

  # A local variable or block argument.
  class Var < ASTNode
    attr_accessor :name
    attr_accessor :out
    attr_accessor :type

    def initialize(name, type = nil)
      @name = name
      @type = type
    end

    def ==(other : self)
      other.name == name && other.type == type && other.out == out
    end
  end

  # An instance variable.
  class InstanceVar < ASTNode
    attr_accessor :name
    attr_accessor :out

    def initialize(name)
      @name = name
    end

    def ==(other : self)
      other.name == name && other.out == out
    end
  end

  class BinaryOp < ASTNode
    attr_accessor :left
    attr_accessor :right

    def initialize(left, right)
      @left = left
      @right = right
    end

    def accept_children(visitor)
      left.accept visitor
      right.accept visitor
    end

    def ==(other : self)
      other.left == left && other.right == right
    end

    def clone_from(other)
      @left = other.left.clone
      @right = other.right.clone
    end
  end

  # Expressions and.
  #
  #     expression '&&' expression
  #
  class And < BinaryOp
  end

  # Expressions or.
  #
  #     expression '||' expression
  #
  class Or < BinaryOp
  end

  # Expressions simple or (no short-circuit).
  #
  #     expression '||' expression
  #
  class SimpleOr < BinaryOp
  end

  # A method definition.
  #
  #     [ receiver '.' ] 'def' name
  #       body
  #     'end'
  #   |
  #     [ receiver '.' ] 'def' name '(' [ arg [ ',' arg ]* ] ')'
  #       body
  #     'end'
  #   |
  #     [ receiver '.' ] 'def' name arg [ ',' arg ]*
  #       body
  #     'end'
  #
  class Def < ASTNode
    attr_accessor :receiver
    attr_accessor :name
    attr_accessor :args
    attr_accessor :body
    attr_accessor :yields
    attr_accessor :maybe_recursive

    def initialize(name, args, body = nil, receiver = nil, yields = false)
      @name = name
      @args = args
      @body = Expressions.from body
      @receiver = receiver
      @yields = yields
    end

    def accept_children(visitor)
      receiver.accept visitor if receiver
      args.each { |arg| arg.accept visitor }
      body.accept visitor if body
    end

    def ==(other : self)
      other.receiver == receiver && other.name == name && other.args == args && other.body == body && other.yields == yields
    end
  end

  # A qualified identifier.
  #
  #     const [ '::' const ]*
  #
  class Ident < ASTNode
    attr_accessor :names
    attr_accessor :global

    def initialize(names, global = false)
      @names = names
      @global = global
    end

    def ==(other : self)
      other.names == names && other.global == global
    end
  end

  # A def argument.
  class Arg < ASTNode
    attr_accessor :name
    attr_accessor :default_value
    attr_accessor :type_restriction
    attr_accessor :out

    def initialize(name, default_value = nil, type_restriction = nil)
      @name = name.to_s
      @default_value = default_value
      @type_restriction = type_restriction
    end

    def accept_children(visitor)
      default_value.accept visitor if default_value
      type_restriction.accept visitor if type_restriction
    end

    def ==(other : self)
      other.name == name && other.default_value == default_value && other.type_restriction == type_restriction && other.out == out
    end
  end

  # A code block.
  #
  #     'do' [ '|' arg [ ',' arg ]* '|' ]
  #       body
  #     'end'
  #   |
  #     '{' [ '|' arg [ ',' arg ]* '|' ] body '}'
  #
  class Block < ASTNode
    attr_accessor :args
    attr_accessor :body

    def initialize(args = [], body = nil)
      @args = args
      @body = Expressions.from body
    end

    def accept_children(visitor)
      args.each { |arg| arg.accept visitor }
      body.accept visitor if body
    end

    def ==(other : self)
      other.args == args && other.body == body
    end
  end

  class SelfRestriction < ASTNode
    def ==(other : self)
      true
    end
  end

  class ControlExpression < ASTNode
    attr_accessor :exps

    def initialize(exps = [])
      @exps = exps
    end

    def accept_children(visitor)
      exps.each { |e| e.accept visitor }
    end

    def ==(other : self)
      other.exps == exps
    end
  end

  class Return < ControlExpression
  end

  class Break < ControlExpression
  end

  class Yield < ControlExpression
  end

  class Next < ControlExpression
  end

  class Include < ASTNode
    attr_accessor :name

    def initialize(name)
      @name = name
    end

    def accept_children(visitor)
      name.accept visitor
    end

    def ==(other : self)
      other.name == name
    end
  end
end
