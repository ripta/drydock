
RSpec.describe Drydock::StreamMonitor do

  describe '#alive?' do
    let(:events) { [] }
    subject { described_class.new(lambda { |e| events << e }).alive? }
    it { is_expected.to be_truthy }
  end
  
end
