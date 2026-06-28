# frozen_string_literal: true

require "setup"

RSpec.describe "LLM::DeepSeek::Images" do
  let(:key) { ENV["DEEPSEEK_SECRET"] || "TOKEN" }
  let(:provider) { LLM.deepseek(key:) }

  context "when given a successful create operation",
          vcr: {cassette_name: "deepseek/images/successful_create"} do
    subject(:response) do
      provider.images.create(
        prompt: "A dog on a rocket to the moon"
      )
    end

    it "is successful" do
      expect(response).to be_instance_of(LLM::Response)
    end

    it "returns an array of images" do
      expect(response.images).to be_instance_of(Array)
    end

    it "returns an IO-like object" do
      expect(response.images[0]).to be_instance_of(StringIO)
    end
  end
end
