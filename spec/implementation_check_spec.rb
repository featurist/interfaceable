# frozen_string_literal: true

require_relative '../lib/interfaceable/implementation_check'

# rubocop:disable Metrics/BlockLength
RSpec.describe Interfaceable::ImplementationCheck do
  it 'checks instance methods' do
    interface = Module.new do
      def foo; end
    end
    klass = Class.new
    errors = Interfaceable::ImplementationCheck.new(klass).perform([interface])

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
    errors = Interfaceable::ImplementationCheck.new(klass).perform([interface])

    expect(errors[interface][:missing_class_methods]).to eq [:foo]
  end

  it 'checks instance method signature' do
    interface = Module.new do
      def foo(aaa, bbb); end
    end
    klass = Class.new do
      def foo(aaa, baz = 3, bar:, fuga: 2); end
    end

    errors = Interfaceable::ImplementationCheck.new(klass).perform([interface])

    expect(errors[interface][:instance_method_signature_errors]).to eq(
      {
        foo: {
          expected: %w[req req],
          actual: ['req', 'opt', :bar, :fuga]
        }
      }
    )

    interface = Module.new do
      def foo(aaa, bbb); end
    end
    klass = Class.new do
      def foo(aaa, baz); end
    end

    errors = Interfaceable::ImplementationCheck.new(klass).perform([interface])

    expect(errors).to be_empty

    interface = Module.new do
      def foo(aaa, bbb); end
    end
    klass = Class.new do
      def foo(aaa, baz, bar = 5, err = nil); end
    end

    errors = Interfaceable::ImplementationCheck.new(klass).perform([interface])

    # allow the class to define additional optional arguments
    expect(errors).to be_empty
  end

  it 'checks class method signature' do
    interface = Module.new do
      def self.foo(aaa, baz = 3, bar:, fuga: 2); end
    end
    klass = Class.new do
      def self.foo(aaa, bbb); end
    end

    errors = Interfaceable::ImplementationCheck.new(klass).perform([interface])

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

    errors = Interfaceable::ImplementationCheck.new(klass).perform([interface])

    expect(errors).to eq({})
  end

  it 'checks *rest argument' do
    interface = Module.new do
      def self.foo(aaa, baz = 3, *args); end
    end
    klass = Class.new do
      def self.foo(aaa, bar = 1); end
    end

    errors = Interfaceable::ImplementationCheck.new(klass).perform([interface])

    expect(errors[interface][:class_method_signature_errors]).to eq(
      {
        foo: {
          expected: %w[req opt rest],
          actual: %w[req opt]
        }
      }
    )

    klass = Class.new do
      def self.foo(aaa, bar = 1, *args); end
    end

    errors = Interfaceable::ImplementationCheck.new(klass).perform([interface])

    expect(errors).to be_empty

    interface = Module.new do
      def self.foo(aaa, baz = 3); end
    end
    klass = Class.new do
      def self.foo(aaa, bar = 1, *args); end
    end

    errors = Interfaceable::ImplementationCheck.new(klass).perform([interface])

    # allow class to define an additional rest argument
    expect(errors).to be_empty
  end

  it 'checks **opts argument' do
    interface = Module.new do
      def foo(aaa, baz = 3, *args, foo:); end
    end
    klass = Class.new do
      def foo(aaa, bar = 1, *args, foo:, **opts); end
    end

    errors = Interfaceable::ImplementationCheck.new(klass).perform([interface])

    # allow the class to have additional rest parameters
    expect(errors).to be_empty

    interface = Module.new do
      def foo(aaa, baz = 3, *args, foo:, **options); end
    end

    errors = Interfaceable::ImplementationCheck.new(klass).perform([interface])
    expect(errors).to be_empty

    klass = Class.new do
      def foo(aaa, bar = 1, *args, foo:); end
    end
    errors = Interfaceable::ImplementationCheck.new(klass).perform([interface])

    expect(errors[interface][:instance_method_signature_errors]).to eq(
      {
        foo: {
          expected: ['req', 'opt', 'rest', :foo, 'keyrest'],
          actual: ['req', 'opt', 'rest', :foo]
        }
      }
    )
  end
end
# rubocop:enable Metrics/BlockLength
