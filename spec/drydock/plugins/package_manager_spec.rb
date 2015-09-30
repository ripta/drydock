
RSpec.describe Drydock::Plugins::PackageManager do

  [:add, :clean, :remove, :update, :upgrade].each do |action|
    describe "##{action}" do
      it 'is not implemented' do
        expect { described_class.new(nil).public_send(action) }.to raise_error(NotImplementedError)
      end
    end
  end

end
