# frozen_string_literal: true

require_relative 'interfacable/implementation_check'
require_relative 'interfacable/error_formatter'

# Ruby interfaces yeah
module Interfacable
  # Subclassing exceptions because other errors don't raise from within `TracePoint.trace`.
  # rubocop:disable Lint/InheritException
  class Error < Exception; end
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
      (@interfaces ||= []).push(*interfaces)

      # rubocop:disable Naming/MemoizedInstanceVariableName
      @interfacable_trace ||= TracePoint.trace(:end) do |t|
        # simplecov does not see inside this block
        # :nocov:
        # rubocop:enable Naming/MemoizedInstanceVariableName
        if self == t.self
          unless (errors = ImplementationCheck.new(self).perform(@interfaces)).empty?
            error_message = ErrorFormatter.new(self).format_errors(errors)
            raise(Error, error_message)
          end

          t.disable
        end
        # :nocov:
      end
    end
  end
end
