# frozen_string_literal: true

require_relative '../lib/interfacable/error_formatter'

# rubocop:disable Metrics/BlockLength
RSpec.describe Interfacable::ErrorFormatter do
  it 'checks instance methods' do
    expected_error = <<~ERROR.chomp
      Stuff must implement:
        - Barable#bar
        - Fooable.foo
      Stuff must implement correctly:
        - Stuffable#stuff:
          - expected arguments: (req, req, opt=, bar:, foo:)
          - actual arguments: (req, opt=, *rest, **keyrest)
    ERROR

    errors = {
      'Barable': {
        missing_instance_methods: [:bar],
        missing_class_methods: [],
        instance_method_signature_errors: {},
        class_method_signature_errors: {}
      },
      'Fooable': {
        missing_class_methods: [:foo],
        missing_instance_methods: [],
        instance_method_signature_errors: {},
        class_method_signature_errors: {}
      },
      'Stuffable': {
        missing_instance_methods: [],
        missing_class_methods: [],
        instance_method_signature_errors: {
          stuff: {
            expected: ['req', 'req', 'opt', :bar, :foo],
            actual: %w[req opt rest keyrest]
          }
        },
        class_method_signature_errors: {}
      }
    }

    actual_error = Interfacable::ErrorFormatter.new('Stuff').format_errors(errors)
    expect(actual_error).to eq(expected_error)
  end

  it 'returns nothing when no errors' do
    actual_error = Interfacable::ErrorFormatter.new('Stuff').format_errors({})
    expect(actual_error).to eq('')
  end
end
# rubocop:enable Metrics/BlockLength
