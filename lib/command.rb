# frozen_string_literal: true

require 'active_support/core_ext/string'
require 'active_model'
require 'dry-initializer'
require 'dry-monads'

require 'gem_ext/active_model/errors' if ActiveModel.version < Gem::Version.new('5.2')
require 'command/failure'
require 'command/input_middleware'
require 'command/interrupt'

module Command
  extend ActiveSupport::Concern

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

    def compose(command, **args)
      outcome = command.run(**args)

      raise Command::Interrupt, outcome.failure.errors if outcome.failure?

      outcome.value!
    end

    def inputs
      self.class.dry_initializer.attributes(self)
    end
  end

  class_methods do
    def run(inputs = {})
      new(**Command::InputMiddleware.call(inputs)).run
    end

    def run!(inputs = {})
      run(inputs).value!
    end
  end
end
