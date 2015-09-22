
RSpec.describe Drydock::Phase do
  
  describe '.from' do

    it 'takes optional values' do
      expect { described_class.from({}) }.not_to raise_error
    end

    [:source_image, :build_container, :result_image].each do |name|
      it "takes a valid #{name} attribute" do
        expect { described_class.from(name => 'value_x') }.not_to raise_error
      end
    end

    it 'rejects an invalid attribute' do
      expect { described_class.from(whatever: 'value_x') }.to raise_error(ArgumentError)
    end

  end

end
