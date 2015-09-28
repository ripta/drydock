
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

  let(:build_container)     { double('BuildContainer') }
  let(:no_build_container)  { described_class.from(source_image: '123', result_image: '456') }
  let(:has_build_container) { described_class.from(source_image: '123', result_image: '456', build_container: build_container) }

  describe '#cached?' do

    context 'when a build container is missing' do
      subject { no_build_container.cached? }
      it { is_expected.to be_truthy }
    end

    context 'when a build container is present' do
      subject { has_build_container.cached? }
      it { is_expected.to be_falsey }
    end

  end

  describe '#built?' do

    context 'when a build container is missing' do
      subject { no_build_container.built? }
      it { is_expected.to be_falsey }
    end

    context 'when a build container is present' do
      subject { has_build_container.built? }
      it { is_expected.to be_truthy }
    end

  end

  describe 'finalize!' do

    it 'when a build container is missing' do
      expect { no_build_container.finalize! }.not_to raise_error
    end

    it 'when a build container is present' do
      expect(build_container).to receive(:remove).with(hash_including(:force))
      expect { has_build_container.finalize! }.not_to raise_error
    end

  end

end
