# Interfacable [![Build Status](https://travis-ci.org/artemave/interfacable.svg?branch=master)](https://travis-ci.org/artemave/interfacable) [![Gem Version](https://badge.fury.io/rb/interfacable.svg)](https://badge.fury.io/rb/interfacable)

Impose interfaces on classes and let this gem automatically check that the interface constraints are met.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'interfacable'
```

And then execute:

    $ bundle install

## Usage

In this example:

```ruby
class Class
  include Interfacable
end

module Carrier
  def call(number); end

  def text(number, text); end
end

class Giffgaff
  implements Carrier
end
```

An attempt to _load_ this code will result in the following error:

    Giffgaff must implement: (Interfacable::Error)
      - Carrier#text
      - Carrier#call

It will keep failing until `Giffgaff` defines those methods.

Correctly. E.g.:

```ruby
class Giffgaff
  def call(number); end

  def text(number); end
end
```

Will fail because of method signature mismatch:

    Giffgaff must implement correctly: (Interfacable::Error)
      - Carrier#text:
        - expected arguments: (req, req)
        - actual arguments: (req)

### Rails

For extra peace of mind, you can noop interface checking in production:

```ruby
# config/initializers/interfacable.rb
class Class
  if Rails.env.production?
    def implements(*args); end
  else
    include Interfacable
  end
end
```
