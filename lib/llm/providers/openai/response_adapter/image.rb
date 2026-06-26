# frozen_string_literal: true

module LLM::OpenAI::ResponseAdapter
  module Image
    def images
      data.filter_map do
        next unless _1["b64_json"]
        StringIO.new(_1["b64_json"].unpack1("m0"))
      end
    end
  end
end
