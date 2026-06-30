# frozen_string_literal: true

module LLM::OpenAI::ResponseAdapter
  module Audio
    def audio
      @audio ||= LLM::URIData.parse(super)
    end
  end
end
