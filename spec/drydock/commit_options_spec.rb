
RSpec.describe Drydock::CommitOptions do

  describe '.new' do
    it 'takes an optional hash' do
      expect { described_class.new }.not_to raise_error
      expect { described_class.new(whatever: true) }.not_to raise_error
    end
  end

  describe '#to_h' do
    subject { options.to_h }

    context 'with the :command option' do
      context 'as a simple string' do
        let(:options) { described_class.new(command: '/bin/ls -l /') }
        it { is_expected.to eq('run' => {Cmd: '/bin/ls -l /'}) }
      end

      context 'as an array' do
        let(:options) { described_class.new(command: ['/bin/sh', '-c', '/bin/ls']) }
        it { is_expected.to eq('run' => {Cmd: ['/bin/sh', '-c', '/bin/ls']}) }
      end
    end

    context 'with the :entrypoint option' do
      context 'as a simple string' do
        let(:options) { described_class.new(entrypoint: '/bin/sh') }
        it { is_expected.to eq('run' => {Entrypoint: '/bin/sh'}) }
      end
    end

    context 'with the :author option' do
      let(:options) { described_class.new(author: 'Ripta Pasay') }
      it { is_expected.to eq(author: 'Ripta Pasay') }
    end

    context 'with the :comment option' do
      let(:options) { described_class.new(comment: 'Implement world domination') }
      it { is_expected.to eq(comment: 'Implement world domination') }
    end
  end

end
