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
      errors = interfaces.each_with_object({}) do |interface, acc|
        missing_implementations = interface.instance_methods.reject do |meth|
          @klass.instance_methods.include?(meth)
        end

        acc[interface] = missing_implementations if missing_implementations.any?
      end

      return if errors.empty?

      raise(NotImplemented, "#{@klass.name} must implement #{formatted_error(errors)}")
    end

    def formatted_error(errors)
      errors.map do |interface, methods|
        methods.map { |meth| "#{interface.name}##{meth}" }
      end.join(', ')
    end
  end
end
