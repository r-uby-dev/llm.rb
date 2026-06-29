# frozen_string_literal: true

module LLM
  class URIData < Struct.new(:content_type, :encoding_type, :encoded, :decoded)
    ##
    # @param [String] str
    #  A string
    # @return [URIData]
    def self.parse(str)
      _, data = str.split(":")
      content_type, data = data.split(";")
      encoding_type, data = data.split(",")
      URIData.new(content_type, encoding_type, data, StringIO.new(data.unpack1("m0")))
    end
  end
end
