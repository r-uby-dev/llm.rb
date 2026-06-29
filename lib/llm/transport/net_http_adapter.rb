# frozen_string_literal: true

class LLM::Transport
  ##
  # @api private
  module NetHTTPAdapter
    private

    def resolve_request(request)
      return request if ::Net::HTTPRequest === request
      build_net_http_request(request)
    end

    def build_net_http_request(req)
      method = req.method.downcase.to_sym
      path = req.path
      headers = req.headers
      http_req = case method
      when :get then ::Net::HTTP::Get.new(path, headers)
      when :post then ::Net::HTTP::Post.new(path, headers)
      when :put then ::Net::HTTP::Put.new(path, headers)
      when :patch then ::Net::HTTP::Patch.new(path, headers)
      when :delete then ::Net::HTTP::Delete.new(path, headers)
      else ::Net::HTTPGenericRequest.new(method, path, nil, headers)
      end
      if req.body
        http_req.body = req.body
      elsif req.body_stream
        http_req.body_stream = req.body_stream
      end
      http_req
    end

    def perform_request(client, request, stream, &b)
      if stream
        client.request(request) do |raw|
          res = LLM::Transport::Response.from(raw)
          if res.success?
            parser = stream.decoder.new(stream.parser.new(stream.streamer))
            res.read_body(parser)
            body = parser.body
            res.body = (Hash === body || Array === body) ? LLM::Object.from(body) : body
          else
            body = +""
            res.read_body { body << _1 }
            res.body = body
          end
        ensure
          parser&.free
        end
      elsif b
        client.request(request) do |raw|
          res = LLM::Transport::Response.from(raw)
          res.success? ? b.call(res) : res
        end
      else
        LLM::Transport::Response.from(client.request(request))
      end
    end
  end
end
