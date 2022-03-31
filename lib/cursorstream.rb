# frozen_string_literal: true

require "solr/cursorstream/version"
require "solr/cursorstream/response"
require "faraday"
require "faraday/retry"

module Solr
  # Fetch results from a solr filter query via solr's cursor streaming.
  # https://solr.apache.org/guide/8_6/pagination-of-results.html#fetching-a-large-number-of-sorted-results-cursors
  #
  # Note that accessors for things like query, filters, etc. are made available for ease of configuration _only_.
  # Changing anything in the middle of a job will screw up the cursors and leave things undetermined. Just
  # make another CursorStream object.
  class CursorStream
    include Enumerable

    class Error < StandardError; end

    attr_accessor :url, :query, :handler, :filters, :sort, :batch_size, :fields, :logger

    # @param [String] url URL to the solr _core_ (e.g., http://my.machine.com/solr/mycore)
    # @param [String] handler The specific handler to target.
    # @param [Array<String>] filters Array of filter queries to apply.
    # @param [String] sort A valid solr sort string. MUST include the unique field (as per solr docs)
    # @param [Integer] batch_size How many results to fetch at a time (for efficiency)
    # @param [Array<String>] fields The solr fields to return.
    # @param [Logger, #info] A logger or logger-like object. When set to `nil` will not do any logging.
    # @param [Symbol] adapter A valid Faraday adapter. If not using the default, it is up to the
    #    programmer to do whatever `require` calls are necessary.

    def initialize(url:, handler: "select", query: "*:*", filters: ["*:*"], sort: "id asc", batch_size: 100, fields: [], logger: nil, adapter: :httpx)
      @url = url.gsub(/\/\Z/, "")
      @query = query
      @handler = handler
      @filters = filters
      @sort = sort
      @batch_size = batch_size
      @fields = fields
      @logger = logger
      @adapter = adapter

      @current_cursor = "*"
      yield self if block_given?
    end

    # @return String solr url build from the passed url and the handler
    def solr_url
      url + "/" + handler
    end

    # Iterate through the documents in the stream. Behind the scenes, these will be fetched in batches
    # of `batch_size` for efficiency.
    # @yieldreturn [Hash] A single solr document from the stream
    def each
      return enum_for(:each) unless block_given?
      verify_we_have_everything!
      while solr_has_more?
        cursor_response = get_page
        cursor_response.docs.each { |d| yield d }
      end
    end

    # Build up a Faraday connection
    # @param [Symbol] adapter Which faraday adapter to use. If not :httpx, you must have loaded the
    # necessary adapter already.
    # @return [Faraday] A faraday connection object.
    def self.connection(adapter: :httpx)
      require "httpx/adapters/faraday" if adapter == :httpx
      Faraday.new do |builder|
        builder.use Faraday::Response::RaiseError

        builder.request :url_encoded
        builder.request :retry
        builder.response :json
        builder.adapter @adapter
      end
    end

    # @see CursorStream.connection
    def connection(adapter: @adapter)
      return @connection if @connection
      @connection = self.class.connection(adapter: @adapter)
    end

    # @private
    # Get a single "page" (`batch_size` documents) from solr. Feeds into #each
    # @return [CursorResponse]
    def get_page
      params = {cursorMark: @current_cursor}.merge default_params
      r = connection.get(solr_url, params)
      resp = Response.new(r)
      @last_cursor = @current_cursor
      @current_cursor = resp.cursor
      resp
    end

    # @private
    # @return [Hash] Default solr params derived from instance variables
    def default_params
      field_list = Array(fields).join(",")
      p = {q: @query, wt: :json, rows: batch_size, sort: @sort, fq: filters, fl: field_list}
      p.reject { |_k, v| [nil, "", []].include?(v) }
      p
    end

    # @private
    # Make sure we have everything we need for a successful stream
    def verify_we_have_everything!
      missing = {handler: @handler, filters: @filters, batch_size: @batch_size}.select { |_k, v| v.nil? }.keys
      raise Error.new("Solr::CursorStreamer missing value for #{missing.join(", ")}") unless missing.empty?
    end

    # @private
    # Determine if solr has another page of results
    # @return [Boolean]
    def solr_has_more?
      @last_cursor != @current_cursor
    end

    # @private
    # @return Lambda that runs every time the connection needs to retry due to http error
    def http_request_retry_block
      ->(env:, options:, retries_remaining:, exception:, will_retry_in:) do
        # TODO: Logging and such
      end
    end
  end
end
