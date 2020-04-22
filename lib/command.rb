# frozen_string_literal: true

require 'active_model'
require 'dry-initializer'
require 'dry-monads'

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
    def run(*args)
      new(*args).run
    end

    def run!(*args)
      run(*args).value!
    end
  end
end
