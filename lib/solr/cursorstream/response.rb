## frozen_string_literal: true

require "delegate"

# Wrapper around a Faraday::Response that provides sugar methods
# to get solr docs, numFound, and the cursor value
class Solr::CursorStream::Response < SimpleDelegator

  # @param [Faraday::Response] faraday_response
  def initialize(faraday_response)
    super
    @base_resp = faraday_response
    @resp = faraday_response.body
    __setobj__(@resp)
  end

  # @return [Array<Hash>] Array of solr documents returned, as simple hashes
  def docs
    @resp["response"]["docs"]
  end

  # @return [Integer] Number of documents found for the solr query
  def num_found
    @resp["response"]["numFound"]
  end

  # @return [String] value of the cursor as returned from solr
  def cursor
    @resp["nextCursorMark"]
  end
end
