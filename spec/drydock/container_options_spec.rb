
RSpec.describe Drydock::ContainerOptions do

  describe '#to_h' do
    context 'with an image ID and command' do
      let(:options) { described_class.new('abcdef0', '/bin/ls /') }

      context 'has the correct image ID' do
        subject { options.to_h[:Image] }
        it { is_expected.to eq('abcdef0') }
      end

      context 'has the correct command' do
        subject { options.to_h[:Cmd] }
        it { is_expected.to eq(['/bin/sh', '-c', '/bin/ls /']) }
      end
    end
  end

end
