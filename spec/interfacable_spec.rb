# frozen_string_literal: true

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
      class Bad
        include Interfacable

        implements Fooable, Barable
      end
    end.to raise_error(Interfacable::NotImplemented, /Bad must implement Fooable#foo, Barable#bar/)
  end

  it 'can call .implements multiple times' do
    expect do
      class Bad
        include Interfacable

        implements Fooable
        implements Barable
      end
    end.to raise_error(Interfacable::NotImplemented, /Bad must implement Fooable#foo, Barable#bar/)
  end
end
