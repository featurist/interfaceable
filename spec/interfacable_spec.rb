# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
RSpec.describe Interfacable do
  it 'has a version number' do
    expect(Interfacable::VERSION).not_to be nil
  end

  module Barable
    def bar; end
  end

  module Fooable
    def foo; end
  end

  module Doable
    def self.do; end

    def stuff; end
  end

  module Stuffable
    def stuff(thing, aaa:, bbb: 2, &block); end
  end

  it 'raises if class does not implement a method' do
    expect do
      class Good
        extend Interfacable

        implements Fooable

        def foo; end
      end
    end.to_not raise_error

    expect do
      class Bad
        include Interfacable

        implements Fooable
      end
    end.to raise_error(Interfacable::NotImplemented, /Bad must implement Fooable#foo/)
  end

  it 'can implement multiples interfaces' do
    expect do
      class Bad2
        include Interfacable

        implements Fooable, Barable
      end
    end.to raise_error(Interfacable::NotImplemented, /Bad2 must implement Fooable#foo, Barable#bar/)
  end

  it 'can call .implements multiple times' do
    expect do
      class Bad3
        include Interfacable

        implements Fooable
        implements Barable
      end
    end.to raise_error(Interfacable::NotImplemented, /Bad3 must implement Fooable#foo, Barable#bar/)
  end

  it 'checks class methods too' do
    expect do
      class Bad5
        include Interfacable
        implements Doable, Barable
      end
    end.to raise_error(Interfacable::NotImplemented, /Bad5 must implement Doable\.do, Doable#stuff, Barable#bar/)
  end

  it 'checks intance method signatures' do
    expect do
      class Bad6
        include Interfacable
        implements Stuffable, Barable

        def stuff(thing); end
      end
    end.to raise_error(
      Interfacable::NotImplemented,
      /Bad6 must implement Barable#bar and match Stuffable#stuff signature/
    )
  end
end
# rubocop:enable Metrics/BlockLength
