# frozen_string_literal: true

require_relative 'interfaceable/implementation_check'
require_relative 'interfaceable/error_formatter'

# Ruby interfaces yeah
module Interfaceable
  # Subclassing exceptions because other errors don't raise from within `TracePoint.trace`.
  # rubocop:disable Lint/InheritException
  class Error < Exception; end
  # rubocop:enable Lint/InheritException

  def implements(*interfaces)
    (@interfaces ||= []).push(*interfaces)

    # rubocop:disable Naming/MemoizedInstanceVariableName
    @interfaceable_trace ||= TracePoint.trace(:end) do |t|
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
