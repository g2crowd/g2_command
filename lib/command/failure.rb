# frozen_string_literal: true

module Command
  class Failure
    attr_reader :result, :errors

    def initialize(result, errors)
      @result = result
      @errors = errors
    end
  end
end
