# frozen_string_literal: true

module LLM::DeepSeek::ResponseAdapter
  module Image
    def images
      [StringIO.new(content!.svg)]
    end
  end
end
