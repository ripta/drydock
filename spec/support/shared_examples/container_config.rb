
RSpec.shared_examples_for 'the same configs' do
  it 'are equal' do
    expect(described_class.from(config1)).to eq(described_class.from(config2))
  end
end

RSpec.shared_examples_for 'different configs' do
  it 'are different' do
    expect(described_class.from(config1)).not_to eq(described_class.from(config2))
  end
end
