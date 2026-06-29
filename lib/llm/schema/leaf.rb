# frozen_string_literal: true

class LLM::Schema
  ##
  # The {LLM::Schema::Leaf LLM::Schema::Leaf} class is the
  # superclass of all values that can appear in a JSON schema.
  # See the instance methods of {LLM::Schema LLM::Schema} for
  # an example of how to create instances of {LLM::Schema::Leaf LLM::Schema::Leaf}
  # through its subclasses.
  class Leaf
    def initialize
      @description = nil
      @default = nil
      @enum = nil
      @required = nil
      @const = nil
    end

    ##
    # Set the description of a leaf
    # @param [String] str The description
    # @return [LLM::Schema::Leaf]
    def description(str = nil)
      if str.nil?
        @description
      else
        tap { @description = str }
      end
    end

    ##
    # Set the default value of a leaf
    # @param [Object] value The default value
    # @return [LLM::Schema::Leaf]
    def default(value = nil)
      if value.nil?
        @default
      else
        tap { @default = value }
      end
    end

    ##
    # Set the allowed values of a leaf
    # @see https://tour.json-schema.org/content/02-Primitive-Types/07-Enumerated-Values-II Enumerated Values
    # @param [Array] values The allowed values
    # @return [LLM::Schema::Leaf]
    def enum(*values)
      if values.empty?
        @enum
      else
        tap { @enum = values }
      end
    end

    ##
    # Set the value of a leaf to be a constant value
    # @see https://tour.json-schema.org/content/02-Primitive-Types/08-Defining-Constant-Values Constant Values
    # @param [Object] value The constant value
    # @return [LLM::Schema::Leaf]
    def const(value = nil)
      if value.nil?
        @const
      else
        tap { @const = value }
      end
    end

    ##
    # Mark a leaf as required
    # @return [LLM::Schema::Leaf]
    def required
      tap { @required = true }
    end

    ##
    # @return [Boolean]
    def required?
      @required
    end

    ##
    # Mark a leaf as optional
    # @return [LLM::Schema::Leaf]
    def optional
      tap { @required = false }
    end

    ##
    # @return [Boolean]
    def optional?
      !@required
    end

    ##
    # @return [Hash]
    def to_h
      {description: @description, default: @default, enum: @enum, const: @const}.compact
    end

    ##
    # @return [String]
    def to_json(options = {})
      to_h.to_json(options)
    end

    ##
    # @return [String]
    def to_s
      LLM::Schema::Renderer.render(self)
    end

    ##
    # @param [LLM::Schema::Leaf] other
    #  An object to compare
    # @return [Boolean]
    def ==(other)
      return false unless self.class === other
      to_h == other.to_h
    end
    alias_method :eql?, :==
  end
end
