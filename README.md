# Interfaceable [![Ruby](https://github.com/featurist/interfaceable/actions/workflows/ruby.yml/badge.svg)](https://github.com/featurist/interfaceable/actions/workflows/ruby.yml) [![Gem Version](https://badge.fury.io/rb/interfaceable.svg)](https://badge.fury.io/rb/interfaceable)

Impose interfaces on classes and let this gem automatically check that the interface constraints are met.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'interfaceable'
```

And then execute:

    $ bundle install

## Usage

In this example:

```ruby
module Carrier
  def call(number); end

  def text(number, text); end
end

class Giffgaff
  extend Interfaceable

  implements Carrier
end
```

An attempt to _load_ this code will result in the following error:

    Giffgaff must implement: (Interfaceable::Error)
      - Carrier#text
      - Carrier#call

It will keep failing until `Giffgaff` defines those methods.

Correctly! E.g.:

```ruby
class Giffgaff
  def call(number); end

  def text(number, text = ''); end
end
```

Will fail because of method signature mismatch:

    Giffgaff must implement correctly: (Interfaceable::Error)
      - Carrier#text:
        - expected arguments: (req, req)
        - actual arguments: (req, opt=)

### Rails

Mix in `Interfaceable` before any of the application code is loaded. For example, in the initializer. For extra peace of mind, you can noop interface checking in production:

```ruby
# config/initializers/interfaceable.rb
class Class
  if Rails.env.production?
    def implements(*args); end
  else
    include Interfaceable
  end
end
```
