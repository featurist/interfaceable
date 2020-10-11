# frozen_string_literal: true

module Interfacable
  # Formats errors
  class ErrorFormatter
    def initialize(class_name)
      @class_name = class_name
    end

    def format_errors(errors)
      error_lines = []

      if (missing_method_errors = formatted_missing_methods_errors(errors)).any?
        error_lines << "#{@class_name} must implement:"
        missing_method_errors.each do |error|
          error_lines << "  - #{error}"
        end
      end

      if (signature_errors = formatted_signature_errors(errors)).any?
        error_lines << "#{@class_name} must implement correctly:"
        signature_errors.each do |(meth, check)|
          error_lines << "  - #{meth}:"
          error_lines << "    - expected arguments: (#{check[:expected].map(&method(:format_arg)).join(', ')})"
          error_lines << "    - actual arguments: (#{check[:actual].map(&method(:format_arg)).join(', ')})"
        end
      end

      error_lines.join("\n")
    end

    private

    def formatted_missing_methods_errors(errors)
      errors.map do |interface, methods|
        methods[:missing_class_methods].map { |meth| "#{interface}.#{meth}" } +
          methods[:missing_instance_methods].map { |meth| "#{interface}##{meth}" }
      end.flatten
    end

    def formatted_signature_errors(errors)
      errors.map do |interface, methods|
        methods[:class_method_signature_errors].map { |meth, check| ["#{interface}.#{meth}", check] } +
          methods[:instance_method_signature_errors].map { |meth, check| ["#{interface}##{meth}", check] }
      end.flatten(1)
    end

    def format_arg(arg)
      case arg
      when 'req'
        'req'
      when 'opt'
        'opt='
      when 'rest'
        '*rest'
      when 'keyrest'
        '**keyrest'
      else
        "#{arg}:"
      end
    end
  end
end
