# frozen_string_literal: true

require "llm"
require "llm/tools/git"
require "llm/tools/read_file"
require "llm/tools/rg"
require "llm/tools/replace_in_file"

class Agent < LLM::Agent
  instructions :set_instructions
  tools :set_tools
  tracer :set_tracer
  concurrency :thread

  def run
    talk("Let's update the changelog")
  end

  private

  def set_instructions
    File.read File.join(__dir__, "prompt.md")
  end

  def set_tools
    [LLM::Tool::Git, LLM::Tool::ReadFile, LLM::Tool::Rg, LLM::Tool::ReplaceInFile]
  end

  def set_tracer
    LLM::Tracer::Logger.new(llm, io: $stderr)
  end
end

def main(argv)
  llm = LLM.deepseek(key: ENV["DEEPSEEK_SECRET"])
  Agent.new(llm).run
end
main(ARGV)
