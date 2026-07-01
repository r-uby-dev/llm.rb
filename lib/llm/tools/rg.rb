# frozen_string_literal

class LLM::Tool
  ##
  # The {LLM::Tool::Rg LLM::Tool::Rg} class implements
  # a frontend to the popular 'rg' tool. The tool can
  # recursively search the current working directory
  # for one or more patterns.
  class Rg < self
    name "rg"
    description "recursively search the current directory for lines matching a pattern"
    parameter :patterns, Array[String], "one or more search patterns"
    required %i[patterns]

    ##
    # @param [String] pattern
    # @return [Hash]
    def call(patterns:)
      command = spawn(patterns:)
      {ok: command.success?, stdout: command.stdout, stderr: command.stderr}
    end

    private

    def spawn(patterns:)
      switch = patterns.size.times.map { "-e" }
      Command.new("rg")
        .argv(*patterns.zip(switch))
        .spawn
  end
end