
RSpec.describe Drydock::PhaseChain do

  EXPECTED_IMAGE_TO_ID_MAPPINGS = {
    'alpine' => {
      '3.2'    => 'f4fddc471ec2',
      'latest' => 'f4fddc471ec2'
    }
  }

  describe '.from_repo' do

    it 'takes a repo name without a tag' do
      expect { described_class.from_repo('alpine') }.not_to raise_error
    end

    it 'takes a repo name and tag' do
      expect { described_class.from_repo('alpine', 'latest') }.not_to raise_error
    end

  end

  describe '#root_image' do

    subject { described_class.from_repo('alpine', '3.2').root_image }

    it 'returns the image object' do
      expect(subject).to be_a(Docker::Image)
    end

    it 'matches the image ID' do
      expect(subject.id).to eq(EXPECTED_IMAGE_TO_ID_MAPPINGS['alpine']['3.2'])
    end

  end

  describe '#images' do

    let(:chain) { described_class.from_repo('alpine', '3.2') }
    subject { chain.images }

    it 'returns only the root object' do
      expect(subject).to eq([chain.root_image])
    end

  end

  describe '#last_image' do

    let(:chain) { described_class.from_repo('alpine', '3.2') }
    subject { chain.last_image }
    it { is_expected.to be_nil }

  end

end
