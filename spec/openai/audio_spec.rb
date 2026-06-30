# frozen_string_literal: true

require "setup"

RSpec.describe "LLM::OpenAI::Audio" do
  let(:key) { ENV["OPENAI_SECRET"] || "TOKEN" }
  let(:provider) { LLM.openai(key:) }

  context "when given a successful create operation",
        vcr: {cassette_name: "openai/audio/successful_create"} do
    subject(:response) { provider.audio.create_speech(input: "A dog on a rocket to the moon") }

    it "is successful" do
      expect(response).to be_instance_of(LLM::Response)
    end

    it "returns an audio" do
      expect(response.audio).to be_instance_of(LLM::URIData)
      expect(response.audio.content_type).to eq("audio/mpeg")
      expect(response.audio.decoded).to be_instance_of(StringIO)
    end
  end

  context "when given a successful transcription operation",
        vcr: {cassette_name: "openai/audio/successful_transcription"} do
    subject(:response) do
      provider.audio.create_transcription(
        file: "spec/fixtures/audio/rocket.mp3"
      )
    rescue => ex
      puts ex.response.body
    end

    it "is successful" do
      expect(response).to be_instance_of(LLM::Response)
    end

    it "returns a transcription" do
      expect(response.text).to eq("A dog on a rocket to the moon.")
    end
  end

  context "when given a successful translation operation",
        vcr: {cassette_name: "openai/audio/successful_translation"} do
    subject(:response) do
      provider.audio.create_translation(
        file: "spec/fixtures/audio/bismillah.mp3"
      )
    end

    it "is successful" do
      expect(response).to be_instance_of(LLM::Response)
    end

    it "returns a translation (Arabic => English)" do
      expect(response.text).to eq("In the name of Allah, the Beneficent, the Merciful.")
    end
  end
end
