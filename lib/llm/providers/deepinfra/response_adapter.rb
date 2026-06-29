# frozen_string_literal: true

class LLM::DeepInfra
  ##
  # @private
  module ResponseAdapter
    module Audio
      def audio
        @audio ||= LLM::URIData.parse(super)
      end
    end

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
      when :audio then Audio
      else LLM::OpenAI::ResponseAdapter.select(type)
      end
    end
  end
end
