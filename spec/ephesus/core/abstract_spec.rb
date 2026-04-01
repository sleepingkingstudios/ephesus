# frozen_string_literal: true

require 'ephesus/core/abstract'

RSpec.describe Ephesus::Core::Abstract do
  let(:described_class) { Spec::CustomClass }

  example_class 'Spec::CustomClass' do |klass|
    klass.include Ephesus::Core::Abstract # rubocop:disable RSpec/DescribedClass
  end

  describe '::AbstractClassError' do
    include_examples 'should define constant',
      :AbstractClassError,
      -> { be_a(Class).and be < StandardError }
  end

  describe '.abstract?' do
    include_examples 'should define class reader', :abstract?, false
  end
end
