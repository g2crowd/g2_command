# frozen_string_literal: true

module Command
  module InputMiddleware
    class RailsParams
      def self.call(inputs)
        class_name = 'ActionController::Parameters'
        klass = class_name.safe_constantize

        return inputs unless klass && inputs.is_a?(klass)

        inputs.to_unsafe_h.to_h
      end
    end
  end
end
