# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Command do
  subject(:command) do
    Class.new do
      include Command

      option :age

      validates :age, numericality: { less_than_or_equal_to: 20 }

      def self.name
        'RunnableClass'
      end

      def execute
        if age == 10
          errors.add(:age, 'must not be equal to 10')
          'goodbye'
        else
          'hello'
        end
      end
    end
  end

  describe '::new' do
    it 'can instantiate with string keys' do
      expect(command.new('age' => 3).age).to eq 3
    end
  end

  describe '::run' do
    context 'when execute is not defined' do
      subject(:command) do
        Class.new { include Command }
      end

      it 'raises an error' do
        expect { command.run }.to raise_error NotImplementedError
      end
    end

    context 'when validations are defined' do
      context 'when validations pass' do
        it 'returns success monad' do
          expect(command.run(age: 20)).to be_success
        end

        it 'contains result' do
          expect(command.run(age: 20).value!).to eq 'hello'
        end
      end

      context 'when validations fail' do
        let(:monad) { command.run(age: 30) }

        it 'returns failure monad' do
          expect(monad).to be_failure
        end

        it 'contains validation message' do
          expect(monad.failure.errors.full_messages.to_sentence).to eq 'Age must be less than or equal to 20'
        end
      end

      context 'when validations fail during execution' do
        let(:monad) { command.run(age: 10) }

        it 'returns failure monad' do
          expect(monad).to be_failure
        end

        it 'contains validation message' do
          expect(monad.failure.errors.full_messages.to_sentence).to eq 'Age must not be equal to 10'
        end

        it 'contains result' do
          expect(monad.failure.result).to eq 'goodbye'
        end
      end
    end
  end

  describe '::run!' do
    context 'when validations pass' do
      it 'returns value' do
        expect(command.run!(age: 20)).to eq 'hello'
      end
    end

    context 'when validations fail' do
      it 'raises error' do
        expect { command.run!(age: 30) }.to raise_error Dry::Monads::UnwrapError
      end
    end
  end

  describe '#compose' do
    subject(:command) do
      Class.new do
        include Command

        option :name

        def self.name
          'RunnableClass'
        end

        def execute
          compose OtherRunnable, name: name
        end
      end
    end

    # rubocop:disable RSpec/LeakyConstantDeclaration
    let!(:other_command) do
      OtherRunnable = Class.new do
        include Command

        option :name

        def execute
          errors.add(:name, 'must not be John') if name == 'John'
          'Successfully ran OtherRunnable'
        end
      end
    end
    # rubocop:enable RSpec/LeakyConstantDeclaration

    after do
      Object.send :remove_const, 'OtherRunnable'
    end

    it 'merges errors' do
      expect(command.run(name: 'John').failure.errors.full_messages.to_sentence).to eq 'Name must not be John'
    end

    it 'returns value' do
      expect(command.run!(name: 'Joe')).to eq 'Successfully ran OtherRunnable'
    end
  end

  describe '#inputs' do
    it 'returns inputs' do
      expect(command.new(age: 30).inputs).to eq age: 30
    end
  end
end
