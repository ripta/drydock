
RSpec.describe Drydock::IgnorefileDefinition do

  describe '.new' do
    it 'raises an error when no filename is provided' do
      expect { described_class.new() }.to raise_error(ArgumentError)
    end

    it 'raises an error when a non-existant file is provided' do
      expect { described_class.new('file_does_not_exist') }.not_to raise_error
    end
  end

  context 'when a file handle with two positive rules is provided' do
    let(:file) { StringIO.new(".gitignore\nvendor") }

    describe '.new' do
      subject { described_class.new(file) }
      it 'reads the entire file' do
        expect(file.eof?).to be(false)
        expect(file.pos).to eq(0)

        expect { subject }.not_to raise_error
        expect(file.eof?).to be(true)
      end
    end

    describe '#match?' do
      context 'for a filename appearing in the ignore file' do
        subject { described_class.new(file).match?('.gitignore') }
        it { is_expected.to be(true) }
      end

      context 'for a regular filename NOT appearing in the ignore file' do
        subject { described_class.new(file).match?('Gemfile') }
        it { is_expected.to be(false) }
      end

      context 'for a dotfile NOT appearing in the ignore' do
        subject { described_class.new(file).match?('.rspec') }
        it { is_expected.to be(false) }
      end
    end

    describe '#size' do
      subject { described_class.new(file).size }
      it { is_expected.to eq(2) }
    end
  end

end
