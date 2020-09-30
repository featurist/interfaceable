# frozen_string_literal: true

# Ruby interfaces yeah
module Interfacable
  # Subclassing exceptions because other errors don't raise from within `TracePoint.trace`.
  # rubocop:disable Lint/InheritException
  class NotImplemented < Exception; end
  # rubocop:enable Lint/InheritException

  def self.extended(base)
    base.extend ClassMethods
  end

  def self.included(base)
    base.extend ClassMethods
  end

  # class methods
  module ClassMethods
    def implements(*interfaces)
      @interfaces ||= []
      @interfaces.push(*interfaces)

      # rubocop:disable Naming/MemoizedInstanceVariableName
      @interfacable_trace ||= TracePoint.trace(:end) do |t|
        # rubocop:enable Naming/MemoizedInstanceVariableName
        if self == t.self
          ImplementationCheck.new(self).perform(@interfaces)

          t.disable
        end
      end
    end
  end

  # Checks if class implements interfaces correctly
  class ImplementationCheck
    def initialize(klass)
      @klass = klass
    end

    def perform(interfaces)
      errors = collect_errors(interfaces)

      return if errors.empty?

      error_parts = []

      if (missing_implementation_errors = formatted_missing_implementations_error(errors))
        error_parts << "implement #{missing_implementation_errors}"
      end

      if (signature_errors = formatted_signature_error(errors))
        error_parts << "match #{signature_errors} signature"
      end

      raise(NotImplemented, "#{@klass} must #{error_parts.join(' and ')}")
    end

    private

    def collect_errors(interfaces)
      interfaces.each_with_object({}) do |interface, acc|
        missing_class_methods = find_missing_class_methods(interface)
        missing_instance_methods = find_missing_instance_methods(interface)
        wrong_signatures = find_wrong_signatures(interface, interface.instance_methods - missing_instance_methods)

        next if missing_instance_methods.none? && missing_class_methods.none? && wrong_signatures.none?

        acc[interface] = {
          missing_instance_methods: missing_instance_methods,
          missing_class_methods: missing_class_methods,
          wrong_signatures: wrong_signatures
        }
      end
    end

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

    def find_wrong_signatures(interface, implemented_methods)
      implemented_methods.reject do |meth|
        expected_parameters = interface.instance_method(meth).parameters
        actual_parameters = @klass.instance_method(meth).parameters

        method_signatures_match?(expected_parameters, actual_parameters)
      end
    end

    def formatted_missing_implementations_error(errors)
      errors.map do |interface, methods|
        methods[:missing_class_methods].map { |meth| "#{interface.name}.#{meth}" } +
          methods[:missing_instance_methods].map { |meth| "#{interface.name}##{meth}" }
      end.flatten.join(', ')
    end

    def formatted_signature_error(errors)
      errors.map do |interface, methods|
        methods[:wrong_signatures].map { |meth| "#{interface.name}##{meth}" }
      end.flatten.join(', ')
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
