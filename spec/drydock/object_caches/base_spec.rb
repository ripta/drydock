
RSpec.describe Drydock::ObjectCaches::Base do

  describe '.new' do
    it 'takes no arguments' do
      expect { described_class.new }.not_to raise_error
    end
  end

  describe '#fetch' do
    it 'is not implemented' do
      expect { described_class.new.fetch(:foo) }.to raise_error(NotImplementedError)
    end
  end

  describe '#get' do
    it 'is not implemented' do
      expect { described_class.new.get(:foo) }.to raise_error(NotImplementedError)
    end
  end

  describe '#set' do
    it 'is not implemented' do
      expect { described_class.new.set(:foo, :some_value) }.to raise_error(NotImplementedError)
    end
  end

end
