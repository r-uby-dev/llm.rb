# frozen_string_literal: true

require "setup"

RSpec.describe "LLM::Context: deepseek" do
  let(:provider) { LLM.deepseek(key:) }
  let(:key) { ENV["DEEPSEEK_SECRET"] || "TOKEN" }
  let(:ctx) { LLM::Context.new(provider, params) }
  let(:params) { {} }

  context LLM::Context do
    include_examples "LLM::Context: completions", :deepseek
    include_examples "LLM::Context: text stream", :deepseek
    include_examples "LLM::Context: tool stream", :deepseek
  end

  context LLM::Function do
    include_examples "LLM::Context: functions", :deepseek
  end

  context LLM::Schema do
    include_examples "LLM::Context: schema", :deepseek
  end
end
