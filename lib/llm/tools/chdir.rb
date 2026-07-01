# frozen_string_literal

class LLM::Tool
  ##
  # The {LLM::Tool::Chdir LLM::Tool::Chdir} class implements
  # a tool that can change the current working directory.
  class Chdir < self
    name "chdir"
    description "change the current working directory"
    parameter :path, String, "the new working directory"
    required %i[path]

    ##
    # @param [String] path
    # @return [Hash]
    def call(path:)
      Dir.chdir(path)
      {ok: true, cwd: path}
    end
  end
end