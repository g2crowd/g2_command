# frozen_string_literal: true

require 'command/input_middleware/rails_params'
require 'command/input_middleware/symbolizer'

module Command
  module InputMiddleware
    MIDDLEWARE = [RailsParams, Symbolizer].freeze

    def self.call(inputs)
      MIDDLEWARE.reduce(inputs) { |memo, middleware| middleware.call(memo) }
    end
  end
end
