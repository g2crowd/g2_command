# frozen_string_literal: true

require 'active_support/core_ext/hash'

module Command
  module InputMiddleware
    class Symbolizer
      def self.call(inputs)
        return inputs unless inputs.is_a?(Hash)

        inputs.to_h.deep_symbolize_keys
      end
    end
  end
end
