# Interfacable [![Build Status](https://travis-ci.org/artemave/interfacable.svg?branch=master)](https://travis-ci.org/artemave/interfacable)

This gem allows you to impose interfaces on classes and automatically checks that interface constraints are met.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'interfacable'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install interfacable

## Usage

In this example:

```ruby
module Carrier
  def call(number); end

  def text(number, text); end
end

class Giffgaff
  include Interfacable

  implements Carrier
end
```

An attempt to run it will result in the following error:

    Giffgaff must implement: (Interfacable::Error)
      - Carrier#text
      - Carrier#call

It will keep failing until `Giffgaff` defines those methods. Correctly. E.g.:

```ruby
class Giffgaff
  def call(number); end

  def text(number); end
end
```

Fail because of method signature mismatch:

    Giffgaff must implement correctly: (Interfacable::Error)
      - Carrier#text:
        - expected arguments: (req, req)
        - actual arguments: (req)
