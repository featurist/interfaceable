# frozen_string_literal: true

module Interfacable
  # Checks if class implements interfaces correctly
  class ImplementationCheck
    def initialize(klass)
      @klass = klass
    end

    def perform(interfaces)
      interfaces.each_with_object({}) do |interface, acc|
        missing_class_methods = find_missing_class_methods(interface)
        missing_instance_methods = find_missing_instance_methods(interface)
        wrong_instance_method_signatures = find_wrong_signatures(interface, :instance_method, interface.instance_methods - missing_instance_methods)
        wrong_static_method_signatures = find_wrong_signatures(interface, :method, own_methods(interface.methods) - missing_class_methods)

        if missing_instance_methods.none? && missing_class_methods.none? && wrong_instance_method_signatures.none? && wrong_static_method_signatures.none?
          next
        end

        acc[interface] = {
          missing_instance_methods: missing_instance_methods,
          missing_class_methods: missing_class_methods,
          wrong_instance_method_signatures: wrong_instance_method_signatures,
          wrong_static_method_signatures: wrong_static_method_signatures
        }
      end
    end

    private

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

    def find_wrong_signatures(interface, method_type, implemented_methods)
      implemented_methods.reject do |meth|
        expected_parameters = interface.send(method_type, meth).parameters
        actual_parameters = @klass.send(method_type, meth).parameters

        method_signatures_match?(expected_parameters, actual_parameters)
      end
    end

    def own_methods(methods)
      methods - Object.methods
    end

    def method_signatures_match?(expected_parameters, actual_parameters)
      expected_keyword_parameters, expected_positional_parameters = split_parameters_by_type(expected_parameters)
      actual_keyword_parameters, actual_positional_parameters = split_parameters_by_type(actual_parameters)

      positional_arguments_match =
        expected_positional_parameters.map(&:first) == actual_positional_parameters.map(&:first)

      keyword_arguments_match =
        expected_keyword_parameters.map(&:last).sort == actual_keyword_parameters.map(&:last).sort

      positional_arguments_match && keyword_arguments_match
    end

    def split_parameters_by_type(parameters)
      parameters.partition { |(arg_type)| arg_type.to_s =~ /^key/ }
    end
  end
end
