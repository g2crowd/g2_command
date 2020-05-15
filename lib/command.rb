# frozen_string_literal: true

require 'active_support/core_ext/string'
require 'active_model'
require 'dry-initializer'
require 'dry-monads'

require 'command/failure'
require 'command/input_middleware'
require 'command/interrupt'

module Command
  extend ActiveSupport::Concern

  # rubocop:disable Metrics/BlockLength
  included do
    extend Dry::Initializer
    include Dry::Monads[:result]
    include ActiveModel::Validations

    def initialize(inputs = {})
      super(**Command::InputMiddleware.call(inputs))
    end

    def execute
      raise NotImplementedError
    end

    def run
      result = if errors.empty? && valid?
                 begin
                   execute
                 rescue Command::Interrupt => e
                   errors.merge! e.errors
                 end
               end

      errors.empty? ? Success(result) : Failure(Command::Failure.new(result, errors))
    end

    def compose(command, *args)
      outcome = command.run(*args)

      raise Command::Interrupt, outcome.failure.errors if outcome.failure?

      outcome.value!
    end

    def inputs
      self.class.dry_initializer.attributes(self)
    end
  end
  # rubocop:enable Metrics/BlockLength

  class_methods do
    def run(inputs = {})
      new(**inputs).run
    end

    def run!(inputs = {})
      run(inputs).value!
    end
  end
end
