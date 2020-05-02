# frozen_string_literal: true

require 'action_controller/metal/strong_parameters'

RSpec.describe Command::InputMiddleware do
  subject(:middleware) { described_class }

  shared_examples 'a symbolized hash' do |inputs|
    it 'returns a hash' do
      expect(middleware.call(inputs)).to be_a Hash
    end

    it 'symbolizes keys' do
      expect(middleware.call(inputs)).to eq age: 20, name: 'John Doe'
    end
  end

  describe '::call' do
    it_behaves_like 'a symbolized hash', ActionController::Parameters.new('age' => 20, 'name' => 'John Doe')
    it_behaves_like 'a symbolized hash', { age: 20, name: 'John Doe' }.with_indifferent_access
    it_behaves_like 'a symbolized hash', { 'age' => 20, 'name' => 'John Doe' }
  end
end
