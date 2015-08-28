
RSpec.describe Drydock::ObjectCaches::NoCache do

  describe '.new' do
    it 'takes no arguments' do
      expect { described_class.new }.not_to raise_error
    end
  end

  describe '#fetch' do
    blk = Proc.new { :value }
    let(:cache) { described_class.new }

    it 'always executes the block' do
      expect(blk).to receive(:call) { :value }.exactly(3).times
      expect { cache.fetch(:foo, &blk) }.not_to raise_error
      expect(cache.fetch(:foo, &blk)).to eq(:value)
      expect(cache.fetch(:foo, &blk)).to eq(:value)
    end
  end

  describe '#get' do
    blk = Proc.new { :value }
    let(:cache) { described_class.new }

    it 'always returns nil' do
      expect(blk).not_to receive(:call)
      expect { cache.get(:foo) }.not_to raise_error
      expect(cache.get(:foo)).to be_nil
    end
  end

  describe '#set' do
    let(:cache) { described_class.new }

    context 'when given a value' do
      it 'returns nil' do
        blk = Proc.new { |f| }
        expect(blk).not_to receive(:call)
        expect(cache.set(:foo, :some_value)).to be_nil
      end
    end

    context 'when given a writer block' do
      it 'returns nil' do
        blk = Proc.new { |f| }
        expect(blk).to receive(:call).once
        expect(cache.set(:foo, &blk)).to be_nil
      end

      it 'invokes the block with a file' do
        file = nil
        blk = Proc.new { |f| }
        expect(blk).to receive(:call) { |f| file = f }.once

        cache.set(:foo, &blk)
        expect(file).to be_an(IO)
      end
    end
  end

end
