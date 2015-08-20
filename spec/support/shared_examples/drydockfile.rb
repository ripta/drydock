
RSpec.shared_examples_for 'a Drydockfile' do
  it do
    expect { described_class.build(opts) { [script, 'Drydockfile'] } }.not_to raise_error
  end
end
