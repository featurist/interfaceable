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

      raise(NotImplemented, "#{@klass.name} must implement #{formatted_error(errors)}")
    end

    private

    def collect_errors(interfaces)
      interfaces.each_with_object({}) do |interface, acc|
        missing_class_methods = get_missing_class_methods(interface)
        missing_instance_methods = get_missing_instance_methods(interface)

        next if missing_instance_methods.none? && missing_class_methods.none?

        acc[interface] = {
          missing_instance_methods: missing_instance_methods,
          missing_class_methods: missing_class_methods
        }
      end
    end

    def get_missing_class_methods(interface)
      interface.methods.reject do |meth|
        @klass.methods.include?(meth)
      end
    end

    def get_missing_instance_methods(interface)
      interface.instance_methods.reject do |meth|
        @klass.instance_methods.include?(meth)
      end
    end

    def formatted_error(errors)
      errors.map do |interface, methods|
        methods[:missing_class_methods].map { |meth| "#{interface.name}.#{meth}" } +
          methods[:missing_instance_methods].map { |meth| "#{interface.name}##{meth}" }
      end.join(', ')
    end
  end
end
