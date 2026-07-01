# frozen_string_literal: true

# frozen_string_literal

class LLM::Tool
  ##
  # The {LLM::Tool::ReadFile LLM::Tool::ReadFile} class implements
  # a tool that can read the contents of a file. The tool accepts
  # two optional offsets: a start line, and a stop line. Without
  # either the entire file contents are read into memory.
  class ReadFile < self
    name "read-file"
    description "read the contents of a file"
    parameter :path, String, "the path to the file"
    parameter :start, Integer, "start line number"
    parameter :stop, Integer, "stop line number"
    required %i[path]

    ##
    # @param [String] path
    # @param [Integer] start
    # @param [Integer] stop
    # @return [Hash]
    def call(path:, start: 1, stop: -1)
      content, cursor = nil, 1
      File.open(path, "r") do |f|
        while cursor < start
          f.gets
          cursor += 1
        end
        if stop == -1
          content = f.read
        else
          content = start.upto(stop).map { f.gets }.join
        end
      end
      {ok: true, content:}
    end
  end
end
