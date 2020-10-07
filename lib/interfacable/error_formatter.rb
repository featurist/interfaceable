# frozen_string_literal: true

module Interfacable
  # Formats errors
  class ErrorFormatter
    def initialize(klass)
      @klass = klass
    end

    def format_errors(errors)
      error_parts = []

      if (missing_method_errors = formatted_missing_methods_errors(errors)).any?
        error_parts << "implement #{missing_method_errors.join(', ')}"
      end

      if (signature_errors = formatted_signature_errors(errors)).any?
        error_parts << "match #{signature_errors.join(', ')} signature#{signature_errors.empty? ? '' : 's'}"
      end

      "#{@klass} must #{error_parts.join(' and ')}"
    end

    private

    def formatted_missing_methods_errors(errors)
      errors.map do |interface, methods|
        methods[:missing_class_methods].map { |meth| "#{interface.name}.#{meth}" } +
          methods[:missing_instance_methods].map { |meth| "#{interface.name}##{meth}" }
      end.flatten
    end

    def formatted_signature_errors(errors)
      errors.map do |interface, methods|
        methods[:class_method_signature_errors].map { |meth| "#{interface.name}.#{meth}" } +
          methods[:instance_method_signature_errors].map { |meth| "#{interface.name}##{meth}" }
      end.flatten
    end
  end
end
