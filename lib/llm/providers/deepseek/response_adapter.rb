# frozen_string_literal: true

class LLM::DeepSeek
  ##
  # @private
  module ResponseAdapter
    require_relative "response_adapter/image"
    module_function

    ##
    # @param [LLM::Response, Net::HTTPResponse] res
    # @param [Symbol] type
    # @return [LLM::Response]
    def adapt(res, type:)
      response = (LLM::Response === res) ? res : LLM::Response.new(res)
      adapter = select(type)
      response.extend(adapter)
    end

    ##
    # @api private
    def select(type)
      case type
      when :image then LLM::DeepSeek::ResponseAdapter::Image
      else LLM::OpenAI::ResponseAdapter.select(type)
      end
    end
  end
end
