# frozen_string_literal: true

RSpec.shared_examples "a persisted llm record" do
  it "resolves a provider instance from the record" do
    expect(record.llm).to be_a(LLM::Provider)
    expect(record.llm).to be_a(LLM::OpenAI)
    expect(record.llm.tracer).to be_a(LLM::Tracer::Logger)
  end

  it "reads usage from the runtime state" do
    expect(record.usage.total_tokens).to eq(0)
  end

  it "persists through #talk" do
    runtime = LLM::Test::Runtime.new
    record.instance_variable_set(:@ctx, runtime)
    expect(record.talk("hello")).to be(runtime.talk_result)
    expect(reload_record.call(record).messages.map(&:content)).to eq(["hello"])
  end

  it "persists through #ask" do
    runtime = LLM::Test::Runtime.new
    record.instance_variable_set(:@ctx, runtime)
    expect(record.ask("hello")).to be(runtime.ask_result)
    expect(reload_record.call(record).messages.map(&:content)).to eq(["hello"])
  end

  it "persists runtime state on the same row" do
    runtime = LLM::Test::Runtime.new
    runtime.messages << LLM::Message.new("user", "hello")
    record.instance_variable_set(:@ctx, runtime)
    flush_record.call(record)
    expect(reload_record.call(record).messages.map(&:content)).to eq(["hello"])
  end
end

RSpec.shared_examples "a persisted context record" do
  include_examples "a persisted llm record"

  it "restores an LLM::Context runtime" do
    expect(record.send(:ctx)).to be_a(LLM::Context)
    expect(record.send(:ctx).params[:store]).to be(false)
  end
end

RSpec.shared_examples "a persisted agent record" do
  include_examples "a persisted llm record"

  it "restores an LLM::Agent runtime" do
    expect(record.send(:ctx)).to be_a(LLM::Agent)
    expect(record.send(:ctx).mode).to eq(:responses)
  end

  it "reads agent defaults from the model class" do
    expect(record.class.agent.model).to eq("gpt-5.4-mini")
    expect(record.class.agent.instructions).to eq("You are concise.")
    expect(record.class.agent.concurrency).to eq(:thread)
  end
end
