# frozen_string_literal: true

# Ruby interfaces yeah
module Interfacable
  # Subclassing exceptions because other errors don't raise from within `TracePoint.trace`.
  # rubocop:disable Lint/InheritException
  class NotImplemented < Exception; end
  # rubocop:enable Lint/InheritException

  def self.included(base)
    base.extend ClassMethods
  end

  # class methods
  module ClassMethods
    # rubocop:disable Metrics/MethodLength
    def implements(*interfaces)
      TracePoint.trace(:end) do |t|
        # This is covered, but simplecov does not see it.
        if self == t.self
          errors = interfaces.each_with_object({}) do |interface, acc|
            missing_implementations = interface.instance_methods.reject do |meth|
              instance_methods.include?(meth)
            end

            acc[interface] = missing_implementations if missing_implementations.any?
          end

          unless errors.empty?
            formatted_error = errors.map do |interface, methods|
              methods.map { |meth| "#{interface.name}##{meth}" }
            end.join(', ')

            raise(NotImplemented, "#{name} must implement #{formatted_error}")
          end

          t.disable
        end
      end
    end
    # rubocop:enable Metrics/MethodLength
  end
end
