# frozen_string_literal: true

module LLM::OpenAI::ResponseAdapter
  module Audio
    ##
    # @return [LLM::URIData]
    def audio
      @audio ||= LLM::URIData.parse(super)
    end
  end
end
