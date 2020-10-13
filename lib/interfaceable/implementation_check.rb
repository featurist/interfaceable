# frozen_string_literal: true

module Interfaceable
  # Checks if class implements interfaces correctly
  class ImplementationCheck
    def initialize(klass)
      @klass = klass
    end

    def perform(interfaces)
      results = validate(interfaces)

      results.reject do |_, checks|
        checks.values.all?(&:empty?)
      end
    end

    private

    # rubocop:disable Metrics/MethodLength
    def validate(interfaces)
      interfaces.each_with_object({}) do |interface, acc|
        missing_class_methods = find_missing_class_methods(interface)
        missing_instance_methods = find_missing_instance_methods(interface)
        instance_method_signature_errors = find_signature_errors(
          interface,
          :instance_method,
          interface.instance_methods - missing_instance_methods
        )
        class_method_signature_errors = find_signature_errors(
          interface,
          :method,
          own_methods(interface.methods) - missing_class_methods
        )

        acc[interface] = {
          missing_instance_methods: missing_instance_methods,
          missing_class_methods: missing_class_methods,
          instance_method_signature_errors: instance_method_signature_errors,
          class_method_signature_errors: class_method_signature_errors
        }
      end
    end
    # rubocop:enable Metrics/MethodLength

    def find_missing_class_methods(interface)
      own_methods(interface.methods).reject do |meth|
        own_methods(@klass.methods).include?(meth)
      end
    end

    def find_missing_instance_methods(interface)
      interface.instance_methods.reject do |meth|
        @klass.instance_methods.include?(meth)
      end
    end

    def find_signature_errors(interface, method_type, implemented_methods)
      implemented_methods.each_with_object({}) do |meth, acc|
        expected_parameters = interface.send(method_type, meth).parameters
        actual_parameters = @klass.send(method_type, meth).parameters

        next unless (errors = check_method_signature(expected_parameters, actual_parameters))

        acc[meth] = {
          expected: errors[:expected_positional_parameters] + errors[:expected_keyword_parameters],
          actual: errors[:actual_positional_parameters] + errors[:actual_keyword_parameters]
        }
      end
    end

    def own_methods(methods)
      methods - Object.methods
    end

    # rubocop:disable Metrics/MethodLength
    def check_method_signature(expected_parameters, actual_parameters)
      expected_keyword_parameters, expected_positional_parameters = simplify_parameters(
        *split_parameters_by_type(expected_parameters)
      )
      actual_keyword_parameters, actual_positional_parameters = simplify_parameters(
        *split_parameters_by_type(actual_parameters)
      )

      return if expected_positional_parameters == actual_positional_parameters &&
                expected_keyword_parameters == actual_keyword_parameters

      {
        expected_positional_parameters: expected_positional_parameters,
        expected_keyword_parameters: expected_keyword_parameters,
        actual_positional_parameters: actual_positional_parameters,
        actual_keyword_parameters: actual_keyword_parameters
      }
    end
    # rubocop:enable Metrics/MethodLength

    def simplify_parameters(keyword_parameters, positional_parameters)
      keyrest = pop_keyrest(keyword_parameters)

      [
        keyword_parameters.map(&:last).sort + (keyrest ? ['keyrest'] : []),
        positional_parameters.map(&:first).reject { |p| p == :block }.map(&:to_s)
      ]
    end

    def pop_keyrest(keyword_parameters)
      return unless keyword_parameters.last && keyword_parameters.last.first == :keyrest

      keyword_parameters.pop
    end

    def split_parameters_by_type(parameters)
      parameters.partition { |(arg_type)| arg_type.to_s =~ /^key/ }
    end
  end
end
