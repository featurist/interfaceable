# frozen_string_literal: true

module Interfaceable
  # Formats errors
  class ErrorFormatter
    def initialize(class_name)
      @class_name = class_name
    end

    def format_errors(errors)
      error_lines = []

      if (missing_method_errors = all_missing_methods_errors(errors)).any?
        error_lines << "#{@class_name} must implement:"
        error_lines << missing_method_errors.map { |error| "  - #{error}" }
      end

      if (signature_errors = all_signature_errors(errors)).any?
        error_lines << "#{@class_name} must implement correctly:"
        error_lines << signature_errors.map(&method(:format_signature_error))
      end

      error_lines.flatten.join("\n")
    end

    private

    def format_signature_error(args)
      meth, check = args
      [
        "  - #{meth}:",
        "    - expected arguments: (#{check[:expected].map(&method(:format_arg)).join(', ')})",
        "    - actual arguments: (#{check[:actual].map(&method(:format_arg)).join(', ')})"
      ]
    end

    def all_missing_methods_errors(errors)
      errors.map do |interface, methods|
        methods[:missing_class_methods].map { |meth| "#{interface}.#{meth}" } +
          methods[:missing_instance_methods].map { |meth| "#{interface}##{meth}" }
      end.flatten
    end

    def all_signature_errors(errors)
      errors.map do |interface, methods|
        methods[:class_method_signature_errors].map { |meth, check| ["#{interface}.#{meth}", check] } +
          methods[:instance_method_signature_errors].map { |meth, check| ["#{interface}##{meth}", check] }
      end.flatten(1)
    end

    def format_arg(arg)
      {
        'req' => 'req',
        'opt' => 'opt=',
        'rest' => '*rest',
        'keyrest' => '**keyrest'
      }.fetch(arg, "#{arg}:")
    end
  end
end
