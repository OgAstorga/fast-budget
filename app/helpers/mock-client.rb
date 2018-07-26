module MockClient
  class << self
    attr_accessor :requests

    def post(url, payload, headers={}, &block)
      if requests.nil?
        @requests = []
      end

      @requests << { url: url, payload: payload, headers: headers, block: block }
    end
  end
end
