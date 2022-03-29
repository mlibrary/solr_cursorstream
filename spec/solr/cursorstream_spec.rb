# frozen_string_literal: true

RSpec.describe Solr::CursorStream do
  it "has a version number" do
    expect(Solr::CursorStream::VERSION).not_to be nil
  end
end
