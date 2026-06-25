# frozen_string_literal: true

require "setup"
require "active_record"
require "sqlite3"
require "stringio"
require "llm/active_record"

RSpec.describe "acts_as_agent" do
  let(:model) { LLM::Test::Harness.build_active_record_model(:spec_active_record_agents) }
  let(:tool) do
    Class.new(LLM::Tool) do
      name "echo"
      description "Echo a value"
    end
  end
  let(:schema) do
    Class.new(LLM::Schema) do
      property :answer, String, "Answer", required: true
    end
  end
  let(:skill_path) { "/tmp/weather" }

  let(:agent) do
    Class.new(model) do
      acts_as_agent(tracer: :set_tracer) do |agent|
        agent.model "gpt-5.4-mini"
        agent.instructions "You are concise."
        agent.concurrency :thread
        agent.confirm "delete-file"
      end

      private

      def set_provider
        LLM.openai(key: "secret")
      end

      def set_context
        {mode: :responses, store: false}
      end

      def set_tracer
        LLM::Tracer::Logger.new(llm, io: StringIO.new)
      end
    end
  end

  let(:record) { agent.create! }
  let(:reload_record) { ->(row) { row.class.find(row.id) } }
  let(:flush_record) { ->(row) { LLM::ActiveRecord::Utils.save!(row, row.send(:ctx), row.class.llm_plugin_options) } }

  it "forwards confirm to the internal agent class" do
    expect(agent.agent.confirm).to eq(["delete-file"])
  end

  context "when tools are declared with a block" do
    let(:agent) do
      tool = self.tool
      Class.new(model) do
        acts_as_agent do |agent|
          agent.tools { [tool] }
        end

        private

        def set_provider
          LLM.openai(key: "secret")
        end
      end
    end

    it "forwards the block to the internal agent class" do
      expect(agent.agent.tools).to be_a(Proc)
    end
  end

  context "when model is declared with a block" do
    let(:agent) do
      Class.new(model) do
        acts_as_agent do |agent|
          agent.model { "gpt-4.1" }
        end

        private

        def set_provider
          LLM.openai(key: "secret")
        end
      end
    end

    it "forwards the block to the internal agent class" do
      expect(agent.agent.model).to be_a(Proc)
    end
  end

  context "when skills are declared with a block" do
    let(:agent) do
      skill_path = self.skill_path
      Class.new(model) do
        acts_as_agent do |agent|
          agent.skills { [skill_path] }
        end

        private

        def set_provider
          LLM.openai(key: "secret")
        end
      end
    end

    it "forwards the block to the internal agent class" do
      expect(agent.agent.skills).to be_a(Proc)
    end
  end

  context "when schema is declared with a block" do
    let(:agent) do
      schema = self.schema
      Class.new(model) do
        acts_as_agent do |agent|
          agent.schema { schema }
        end

        private

        def set_provider
          LLM.openai(key: "secret")
        end
      end
    end

    it "forwards the block to the internal agent class" do
      expect(agent.agent.schema).to be_a(Proc)
    end
  end

  include_examples "a persisted agent record"

  context "with a live OpenAI completion",
          vcr: {cassette_name: "openai/chat/completion_contract"} do
    let(:agent) do
      Class.new(model) do
        acts_as_agent(tracer: :set_tracer) do |agent|
          agent.model "gpt-4.1"
        end

        private

        def set_provider
          LLM.openai(key: "secret")
        end

        def set_tracer
          LLM::Tracer::Logger.new(llm, io: StringIO.new)
        end
      end
    end

    let(:record) { agent.create! }

    it "persists the returned messages" do
      result = record.talk("Hello, world!")
      expect(result).to be_a(LLM::Response)
      expect(reload_record.call(record).messages.last).to be_a(LLM::Message)
      expect(reload_record.call(record).messages.last.content).not_to be_empty
    end
  end
end
