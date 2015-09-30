
RSpec.describe Drydock::CliFlags do

  describe '#to_s' do

    context 'single-character flags' do
      subject { described_class.new(v: true, t: false, a: nil).to_s }
      it { is_expected.to eq('-v -t -a ') }
    end

    context 'multiple-character positive flags' do
      subject { described_class.new(verbose: true).to_s }
      it { is_expected.to eq('--verbose ') }
    end

    context 'multiple-character negative flags' do
      subject { described_class.new(verbose: false).to_s }
      it { is_expected.to eq('--no-verbose ') }
    end

    context 'multiple-character string flags without whitespace' do
      subject { described_class.new(tag: 'drydock/test:1.0').to_s }
      it { is_expected.to eq('--tag drydock/test:1.0') }
    end

    context 'multiple-character string flags with whitespace' do
      subject { described_class.new(author: 'John Doe').to_s }
      it { is_expected.to eq('--author "John Doe"') }
    end

    context 'multiple-character numeric flags' do
      subject { described_class.new(value: 2.5).to_s }
      it { is_expected.to eq('--value 2.5') }
    end

  end

end
