# frozen_string_literal: true

require_relative "lib/solr/cursorstream/version"

Gem::Specification.new do |spec|
  spec.name = "solr_cursorstream"
  spec.version = Solr::CursorStream::VERSION
  spec.authors = ["Bill Dueber"]
  spec.email = ["bill@dueber.com"]

  spec.summary = "Get an iterator on a solr filter using stream/cursor"
  spec.homepage = "https://github.com/mlibrary/solr_cursorstream"
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage + "/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday"
  spec.add_dependency "faraday-retry"
  spec.add_dependency "httpx"
  spec.add_dependency "milemarker"

  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "standard"
end
