# frozen_string_literal: true

require_relative '../lib/interfacable/implementation_check'

# rubocop:disable Metrics/BlockLength
RSpec.describe Interfacable::ImplementationCheck do
  it 'checks instance methods' do
    interface = Module.new do
      def foo; end
    end
    klass = Class.new
    errors = Interfacable::ImplementationCheck.new(klass).perform([interface])

    expect(errors[interface]).to eq(
      {
        missing_instance_methods: [:foo],
        missing_class_methods: [],
        instance_method_signature_errors: {},
        class_method_signature_errors: {}
      }
    )
  end

  it 'checks class methods' do
    interface = Module.new do
      def self.foo; end
    end
    klass = Class.new
    errors = Interfacable::ImplementationCheck.new(klass).perform([interface])

    expect(errors[interface][:missing_class_methods]).to eq [:foo]
  end

  it 'checks instance method signature' do
    interface = Module.new do
      def foo(aaa, bbb); end
    end
    klass = Class.new do
      def foo(aaa, baz = 3, bar:, fuga: 2); end
    end

    errors = Interfacable::ImplementationCheck.new(klass).perform([interface])

    expect(errors[interface][:instance_method_signature_errors]).to eq(
      {
        foo: {
          expected: %w[req req],
          actual: ['req', 'opt', :bar, :fuga]
        }
      }
    )
  end

  it 'checks class method signature' do
    interface = Module.new do
      def self.foo(aaa, baz = 3, bar:, fuga: 2); end
    end
    klass = Class.new do
      def self.foo(aaa, bbb); end
    end

    errors = Interfacable::ImplementationCheck.new(klass).perform([interface])

    expect(errors[interface][:class_method_signature_errors]).to eq(
      {
        foo: {
          expected: ['req', 'opt', :bar, :fuga],
          actual: %w[req req]
        }
      }
    )
  end

  it 'ignores &block argument' do
    interface = Module.new do
      def foo(aaa, bbb:, &block); end
    end
    klass = Class.new do
      def foo(aaa, bbb:); end
    end

    errors = Interfacable::ImplementationCheck.new(klass).perform([interface])

    expect(errors).to eq({})
  end
end
# rubocop:enable Metrics/BlockLength
