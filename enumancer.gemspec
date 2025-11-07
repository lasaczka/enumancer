Gem::Specification.new do |spec|
  spec.name        = 'enumancer'
  spec.version     = '1.0.0'
  spec.summary     = 'Easy to use typed enums.'
  spec.description = <<DESC
    Enumancer provides a predictable, type-safe registry for named values.
    Each entry is unique by both name and value, with optional type constraints and strict mode.
DESC
  spec.authors     = ['Łasačka']
  spec.email       = 'saikinmirai@gmail.com'
  spec.files       = ['lib/enum.rb']
  spec.homepage    = 'https://github.com/lasaczka/enumancer'

  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['bug_tracker_uri'] = "#{spec.homepage}/issues"
  spec.metadata['documentation_uri'] = "https://rubydoc.info/gems/kolor/#{spec.version}"

  spec.license       = 'BSD-3-Clause-Attribution'
  spec.required_ruby_version = '>= 3.0.0'
end