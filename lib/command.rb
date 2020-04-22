# frozen_string_literal: true

require 'active_support/core_ext/string'
require 'active_model'
require 'dry-initializer'
require 'dry-monads'

require 'command/input_middleware'
require 'command/interrupt'

module Command
  extend ActiveSupport::Concern

  included do
    extend Dry::Initializer
    include Dry::Monads[:result]
    include ActiveModel::Validations

    def execute
      raise NotImplementedError
    end

    def run
      result = if valid?
                 begin
                   execute
                 rescue Command::Interrupt => e
                   errors.merge! e.errors
                 end
               end

      errors.empty? ? Success(result) : Failure(errors)
    end

    def compose(command, *args)
      outcome = command.run(*args)

      raise Command::Interrupt, outcome.failure if outcome.failure?

      outcome.value!
    end

    def inputs
      self.class.dry_initializer.attributes(self)
    end
  end

  class_methods do
    def run(inputs = {})
      new(normalize_inputs(inputs)).run
    end

    def run!(inputs = {})
      run(inputs).value!
    end

    private

    def normalize_inputs(inputs)
      Command::InputMiddleware.call(inputs)
    end
  end
end
