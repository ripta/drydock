
RSpec.describe Drydock::Formatters do

  describe '.number' do
    context 'a small integer' do
      subject { described_class.number(2) }
      it { is_expected.to eq('2') }
    end

    context 'a large integer' do
      subject { described_class.number(5196714) }
      it { is_expected.to eq('5,196,714') }
    end

    context 'a large decimal' do
      subject { described_class.number(1024.66) }
      it { is_expected.to eq('1,024.66') }
    end

    context 'a negative decimal' do
      subject { described_class.number(-24.52) }
      it { is_expected.to eq('-24.52') }
    end
  end

end
