# Enumancer

[![Gem Version](https://badge.fury.io/rb/enumancer.svg)](https://badge.fury.io/rb/enumancer)
[![License: BSD-3-Clause](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

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
