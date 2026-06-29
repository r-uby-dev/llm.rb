# frozen_string_literal: true

class LLM::DeepSeek
  ##
  # @private
  module RequestAdapter
    require_relative "request_adapter/completion"

    ##
    # @param [Array<LLM::Message>] messages
    #  The messages to adapt
    # @return [Array<Hash>]
    def adapt(messages, mode: nil)
      messages.filter_map do |message|
        Completion.new(message).adapt
      end
    end

    private

    ##
    # Adapt a schema for the DeepSeek chat completions API.
    #
    # DeepSeek does not support OpenAI's `json_schema` response format,
    # so llm.rb falls back to `json_object` and injects a system message
    # that describes the expected shape in prompt-friendly terms.
    #
    # @param [Hash] params
    #  The request params
    # @return [Hash]
    def adapt_schema(params)
      return {} unless params && params[:schema]
      schema = params.delete(:schema)
      schema = schema.respond_to?(:object) ? schema.object : schema
      params[:messages] ||= []
      params[:messages] << LLM::Message.new(system_role, adapt_prompt(schema))
      {response_format: {type: "json_object"}}
    end

    ##
    # Build the system prompt that describes the schema.
    # @param [#to_s] schema
    #  The schema object
    # @return [String]
    def adapt_prompt(schema)
      "Respond with a single valid JSON object. " \
      "Do not include markdown, code fences, commentary, or any text outside the JSON object. " \
      "The JSON object must match this schema: " \
      "#{schema}"
    end

    ##
    # @param [Array<LLM::Function>] tools
    # @return [Hash]
    def adapt_tools(tools)
      (tools.nil? || tools.empty?) ? {} : {tools: tools.map { _1.adapt(self) }}
    end
  end
end
