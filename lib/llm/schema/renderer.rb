# frozen_string_literal: true

class LLM::Schema
  ##
  # Internal renderer for prompt-friendly schema output.
  # @api private
  module Renderer
    extend self

    ##
    # Render a schema node as a human-readable string.
    # @param [LLM::Schema::Leaf] node
    #  The schema node to render
    # @param [Integer] indent
    #  The indentation level
    # @param [String, Symbol, nil] name
    #  The property name for nested nodes
    # @param [Boolean] root
    #  Whether the node is the root schema object
    # @return [String]
    def render(node, indent: 0, name: nil, root: false)
      line = +"#{" " * indent}"
      if name
        line << name.to_s
        line << "?" unless node.required?
        line << ": "
      end
      line << type_name(node)
      metadata = metadata_for(node, include_required: !root)
      line << " (#{metadata.join(', ')})" unless metadata.empty?
      line << " - #{node.description}" if node.respond_to?(:description) && node.description
      nested = nested_lines(node, indent: indent + 2)
      ([line] + nested).join("\n")
    end

    private

    ##
    # Render nested lines for compound schema nodes.
    # @param [LLM::Schema::Leaf] node
    #  The schema node
    # @param [Integer] indent
    #  The indentation level
    # @return [Array<String>]
    def nested_lines(node, indent:)
      case node
      when LLM::Schema::Object
        node.properties.map { |key, val| render(val, indent:, name: key) }
      when LLM::Schema::Array
        items = node.to_h[:items]
        items.is_a?(LLM::Schema::Object) ? [render(items, indent:, name: "items")] : []
      else
        []
      end
    end

    ##
    # Return the printable type name for a schema node.
    # @param [LLM::Schema::Leaf] node
    #  The schema node
    # @return [String]
    def type_name(node)
      h = node.to_h
      return "array<#{inline_type(h[:items])}>" if node.is_a?(LLM::Schema::Array)
      return "anyOf<#{inline_types(h[:anyOf])}>" if node.is_a?(LLM::Schema::AnyOf)
      return "oneOf<#{inline_types(h[:oneOf])}>" if node.is_a?(LLM::Schema::OneOf)
      return "allOf<#{inline_types(h[:allOf])}>" if node.is_a?(LLM::Schema::AllOf)
      h[:type] || "unknown"
    end

    ##
    # Return the inline type description for a nested node.
    # @param [LLM::Schema::Leaf, Object] node
    #  The nested schema node
    # @return [String]
    def inline_type(node)
      return type_name(node) if node.is_a?(LLM::Schema::Leaf)
      node.inspect
    end

    ##
    # Return the inline type description for a list of nodes.
    # @param [Array<LLM::Schema::Leaf>] values
    #  The union members
    # @return [String]
    def inline_types(values)
      values.map { inline_type(_1) }.join(", ")
    end

    ##
    # Extract printable metadata for a schema node.
    # @param [LLM::Schema::Leaf] node
    #  The schema node
    # @param [Boolean] include_required
    #  Whether to include the required marker
    # @return [Array<String>]
    def metadata_for(node, include_required:)
      h = node.to_h.dup
      details = []
      details << "required" if include_required && node.required?
      details << "default: #{value(node.default)}" if node.default
      details << "enum: #{node.enum.map { value(_1) }.join(' | ')}" if node.enum
      details << "const: #{value(node.const)}" if node.const
      h.except(:type, :description, :default, :enum, :const, :required, :properties, :items, :anyOf, :oneOf, :allOf)
        .each { |key, val| details << "#{key}: #{value(val)}" }
      details
    end

    ##
    # Convert a scalar value into its printable representation.
    # @param [Object] val
    #  The value to render
    # @return [String]
    def value(val)
      case val
      when ::String then val.inspect
      else val.to_s
      end
    end
  end
end
