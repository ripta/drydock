
RSpec.describe Drydock::IgnorefileDefinition do

  describe '.new' do
    it 'raises an error when no filename is provided' do
      expect { described_class.new() }.to raise_error(ArgumentError)
    end

    it 'raises an error when a non-existant file is provided' do
      expect { described_class.new('file_does_not_exist') }.not_to raise_error
    end
  end

  context 'when given a file handle with two positive rules' do
    let(:file) { StringIO.new(".gitignore\nvendor/ruby") }
    let(:ifd)  { described_class.new(file) }

    describe '.new' do
      subject { ifd }
      it 'reads the entire file' do
        expect(file.eof?).to be(false)
        expect(file.pos).to eq(0)

        expect { subject }.not_to raise_error
        expect(file.eof?).to be(true)
      end
    end

    describe '#match?' do
      context 'for a filename appearing in the ignore file' do
        subject { ifd.match?('.gitignore') }
        it { is_expected.to be(true) }
      end

      context 'for a directory name not exactly appearing in the ignore file' do
        subject { ifd.match?('vendor') }
        it { is_expected.to be(false) }
      end

      context 'for a directory name appearing in the ignore file' do
        subject { ifd.match?('vendor/ruby') }
        it { is_expected.to be(true) }
      end

      context 'for a regular filename NOT appearing in the ignore file' do
        subject { ifd.match?('Gemfile') }
        it { is_expected.to be(false) }
      end

      context 'for a dotfile NOT appearing in the ignore' do
        subject { ifd.match?('.rspec') }
        it { is_expected.to be(false) }
      end
    end

    describe '#size' do
      subject { ifd.size }
      it { is_expected.to eq(2) }
    end
  end

  context 'when given a file handle with a negative rule' do
    let(:file) { StringIO.new("!.gitignore") }
    let(:ifd)  { described_class.new(file) }

    describe '#match?' do
      context 'for a filename excluded in the ignore file' do
        subject { ifd.match?('.gitignore') }
        it { is_expected.to be(false) }
      end

      context 'for a filename not excluded in the ignore file' do
        subject { ifd.match?('Gemfile') }
        it { is_expected.to be(false) }
      end
    end

    describe '#size' do
      subject { ifd.size }
      it { is_expected.to eq(1) }
    end
  end

  context 'when given an empty file handle with automatic dotfile handling' do
    let(:file) { StringIO.new("") }
    let(:ifd)  { described_class.new(file, dotfiles: true) }

    describe '#match?' do
      context 'for a dotfile' do
        subject { ifd.match?('.gitignore') }
        it { is_expected.to eq(true) }
      end
    end

    describe '#size' do
      subject { ifd.size }
      it { is_expected.to eq(0) }
    end
  end

  context 'when given a file handle with a wildcard' do
    let(:file) { StringIO.new("Gemfile*") }
    let(:ifd)  { described_class.new(file) }

    describe '#match?' do
      context 'for an exact match' do
        subject { ifd.match?('Gemfile')}
        it { is_expected.to eq(true) }
      end

      context 'for a substring prefix match' do
        subject { ifd.match?('Gemfile.lock') }
        it { is_expected.to eq(true) }
      end

      context 'for a substring suffix match' do
        subject { ifd.match?('NotGemfile') }
        it { is_expected.to eq(false) }
      end
    end
  end

end
