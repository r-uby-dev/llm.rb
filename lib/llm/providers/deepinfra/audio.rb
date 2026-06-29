# frozen_string_literal: true

class LLM::DeepInfra
  class Audio
    ##
    # @param [LLM::Provider] provider
    #  A provider
    # @return [LLM::DeepInfra::Audio]
    def initialize(provider)
      @provider = provider
    end

    ##
    # @param [String] input
    #  A string of text
    # @param [String] model
    #  A text-to-speech model.
    #  Defaults to hexgrad/Kokoro-82M.
    # @param [Hash] params
    #  Any other model-specific parameters
    # @return [LLM::Response]
    def create_speech(input:, model: "hexgrad/Kokoro-82M", **params)
      path = path("/v1/inference/#{model}", base_path: false)
      req = LLM::Transport::Request.post(path, headers)
      req.body = JSON.dump(params.merge(text: input))
      res, span, tracer = execute(request: req, operation: "request")
      res = ResponseAdapter.adapt LLM::Response.new(res), type: :audio
      tracer.on_request_finish(operation: "request", model:, res:, span:)
      res
    end

    ##
    # @raise [NotImplementedError]
    def create_translation(...)
      raise NotImplementedError
    end

    private

    [:path, :headers, :execute, :transport].each do |m|
      define_method(m) { |*args, **kwargs, &b| @provider.send(m, *args, **kwargs, &b) }
    end
  end
end
