# Solr::CursorStream

"Stream" results from solr with 
[cursor-based fetching](https://solr.apache.org/guide/8_6/pagination-of-resultshtml#fetching-a-large-number-of-sorted-results-cursors), 
exposing the stream as a normal ruby enumerator. 

Note that this is different from true streaming of results via, e.g.,
the [default `/export` handler](https://solr.apache.org/guide/8_6/exporting-result-sets.html).

Those queries can involve more complex processing, but don't fit all use 
cases:
  * `/export` can't use relevancy ranking as a sort; `Solr::CursorStream` can 
  * `/export` requires all fields have to be `docValues`, 
    `Solr::CursorStream` doesn't.

Cursor-based streaming allows, with some restrictions, 
downloading large sets of data without the "deep paging" 
out-of-memory problems 
associated with just using the `start` and `rows` parameters. 

The only significant restrictions is that _the sort specification MUST 
include the`uniqueKey` field_. If you're just downloading a whole dataset and 
don't care about order, the default query of `*:*` and the default sort of `id asc`
will be fine (assuming your uniqueKey is `id`). If you want to sort by
another field/value, you must use the uniqueKey in a secondary sort (e.g., 
`sort: "score desc, id asc"`) to guarantee a stable sort. 

NOTE that if you don't need the `score` (relevancy) field, 
_use the default query parameter of `*:*`_ so
solr doesn't have to work as hard. Just put your restrictions in the
`filters` array. 

## Usage

```ruby
require 'solr/cursorstream'

core_url = "http://my.solr.com:8025/solr/mycore/"

# Get everything in the solr core, no restrictions
cs = Solr::CursorStream.new(url: core_url)
cs.each {|doc| ... }

# Filter for newer stuff
# Note that you need to lucene-escape any q/fq values on your own, since
# otherwise we'd need a full solr syntax parser to determine which
# bits to escape.
cs = Solr::CursorStream.new(url: core_url, filters = ['year:{2010 TO *}'])

# Find everything with the phrase "Civil War" in the title and 
# pre-20th century, ordered by year
cs = Solr::CursorStream.new(url: core_url) do |s|
  s.filters = ['year:[* TO 1900]', 'title:"Civil War"']
  s.sort = 'year asc, id asc' # need to include the uniqueKey field (id)!  
end

# #each yields a solr document hash until it runs out 
cs.each {|doc| ... }

# The underlying Faraday http connection is available if you need
# to mess with it directly
cs.connection.set_basic_auth(user, password)

# There are a _lot_ of possible arguments to `new`. It may be easier
# to specify values in a block
cs = Solr::CursorStream.new(url: core_url) do |s|
  s.batch_size = 100
  s.fields = %w[id title author year]
  s.filters = ["year:[* TO 1900]"]
  s.query = "title:(Civil War)"
  s.sort = 'score desc, id asc'
end

# Get the first 10_000 results from a query
cs.each_with_index do |doc, i|
  break if i >= 10_000
  do_someting_with_the_solr_doc(doc)
end

```

## TODO

[ ] Add a :limit option
[ ] Add a `lucene_escape` utility function
[ ] Change q/fq to take either a string (as current) or a {field => value} hash
[ ] Actual error handling, or at least passing useful information along
[ ] Figure out how to test without a live solr to bounce off of. Maybe use 
vcr or similar?

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'solr_cursorstream'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install solr_cursorstream



## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mlibrary/solr_cursorstream.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
