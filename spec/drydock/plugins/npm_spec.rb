
RSpec.describe Drydock::Plugins::NPM do

  let(:project) { double('Project') }
  let(:plugin)  { described_class.new(project) }

  describe '#install' do

    it 'adds one package' do
      expect(project).to receive(:run).with('npm install sinopia')
      expect { plugin.install('sinopia') }.not_to raise_error
    end

    it 'adds one package globally' do
      expect(project).to receive(:run).with('npm install -g bower')
      expect { plugin.install('bower', g: true) }.not_to raise_error
    end

    it 'adds more than one packages' do
      expect(project).to receive(:run).with('npm install sinopia bower')
      expect { plugin.install('sinopia', 'bower') }.not_to raise_error
    end

  end

end
