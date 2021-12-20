# frozen_string_literal: true

module Command
  module InputMiddleware
    class Symbolizer
      def self.call(inputs)
        return inputs unless inputs.is_a?(Hash)

        inputs.to_h.symbolize_keys
      end
    end
  end
end
