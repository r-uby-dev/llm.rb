# frozen_string_literal: true

# frozen_string_literal

class LLM::Tool
  ##
  # The {LLM::Tool::Shell} class implements a tool that can
  # spawn a command. That can be dangerous given a low-quality
  # model, or a high-quality model that simply makes a bad
  # decision. The risk can be reduced through a confirmation
  # step such as {LLM::Agent.confirm LLM::Agent.confirm}, or
  # by managing the tool loop manually through
  # {LLM::Context LLM::Context}.
  class Shell < self
    name "shell"
    description "run a shell command"
    parameter :name, String, "the command name"
    parameter :arguments, Array[String], "one or more command arguments"
    required %i[name]

    ##
    # @param [String] name
    #  The name of a command
    # @param [Array<String>] arguments
    #  One or more command-line arguments
    # @return [Hash]
    def call(name:, arguments: nil)
      command = spawn(name:, arguments:)
      {ok: command.success?, stdout: command.stdout, stderr: command.stderr}
    end

    private

    ##
    # @param [String] name
    # @param [Array<String>] arguments
    # @return [Command]
    def spawn(name:, arguments:)
      Command
        .new(name)
        .argv(*[*arguments])
        .spawn
    end

    LLM.require "test-cmd.rb"
    Command = Test::Cmd
  end
end
