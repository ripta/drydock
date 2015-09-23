
RSpec.describe Drydock::Plugins::Rubygems do

  let(:project) { double('Project') }
  let(:plugin)  { described_class.new(project) }

  describe '#add_source' do

    it 'adds one source' do
      expect(project).to receive(:run).with('gem sources --add http://whatever/')
      expect { plugin.add_source('http://whatever/') }.not_to raise_error
    end

  end

  describe '#remove_source' do

    it 'removes one source' do
      expect(project).to receive(:run).with('gem sources --remove http://whatever/')
      expect { plugin.remove_source('http://whatever/') }.not_to raise_error
    end

  end

  describe '#install' do

    it 'installs one package' do
      expect(project).to receive(:run).with('gem install curb ', timeout: 120)
      expect { plugin.install('curb') }.not_to raise_error
    end

    it 'installs one package with timeout' do
      expect(project).to receive(:run).with('gem install curb ', timeout: 45)
      expect { plugin.install('curb', timeout: 45) }.not_to raise_error
    end

    it 'installs one package without docs' do
      expect(project).to receive(:run).with('gem install curb --no-rdoc --no-ri ', timeout: 120)
      expect { plugin.install('curb', rdoc: false, ri: false) }.not_to raise_error
    end

  end

end
