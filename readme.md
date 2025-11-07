# Enumancer

![Gem Version](https://img.shields.io/gem/v/enumancer?include_prereleases&logo=rubygems&logoColor=%23e0e0e0&label=version&labelColor=%23FF748C&color=pink&style=for-the-badge)(https://rubygems.org/gems/enumancer) &nbsp;
[![License: BSD-3-Clause](https://img.shields.io/badge/license-BSD--3--Clause-pink?labelColor=%23FF748C&logoColor=%23e0e0e0&style=for-the-badge&logo=bsd)](https://opensource.org/licenses/BSD-3-Clause)

**Enumancer** provides a declarative, type-safe registry for named values in Ruby.  
Each entry is unique by both name and value. Optional type constraints and strict mode are supported.  
Designed for predictable access, JSON serialization, and clean integration into Ruby applications.

---

## Installation

Add this line to your Gemfile:

```ruby
gem 'enumancer'
```

Then install:

```sh
bundle install
```

Or install it directly:

```sh
gem install enumancer
```

---

## Usage

```ruby
class Status < Enumancer::Enum
  type Integer, strict: true

  entry :draft, 0
  entry :published, 1
  entry :archived, 2
end

Status[:draft].value      # => 0
Status.published.to_sym   # => :published
Status.from_json('{"name":"archived"}') # => Status.archived
```

---

## Serialization

```ruby
Status.draft.to_json
# => '{"name":"draft","value":0}'
```

---

## Deserialization

```ruby
Status.from_json('{"name":"published"}')
# => Status.published
```
