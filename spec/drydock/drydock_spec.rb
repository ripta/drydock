
RSpec.describe Drydock do

  describe '.build' do

    let(:opts) { Hash.new }

    context 'with an empty script' do
      let(:script) { "" }
      it_behaves_like 'a Drydockfile'
    end

    context 'from the scratch image' do
      let(:script) { "from 'scratch'" }
      it_behaves_like 'a Drydockfile'
    end

    context 'from an Alpine Linux image' do
      let(:script) { "from 'gliderlabs/alpine'" }
      it_behaves_like 'a Drydockfile'
    end

  end

end
