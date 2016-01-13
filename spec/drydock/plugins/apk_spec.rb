
RSpec.describe Drydock::Plugins::APK do

  let(:project) { double('Project') }
  let(:plugin)  { described_class.new(project) }

  describe '#add' do

    it 'adds one package' do
      expect(project).to receive(:run).with('apk add ruby', {})
      expect { plugin.add('ruby') }.not_to raise_error
    end

    it 'adds more than one packages' do
      expect(project).to receive(:run).with('apk add curl ruby nodejs', {})
      expect { plugin.add('curl', 'ruby', 'nodejs') }.not_to raise_error
    end

  end

  describe '#remove' do

    it 'deletes one package' do
      expect(project).to receive(:run).with('apk del ruby', {})
      expect { plugin.remove('ruby') }.not_to raise_error
    end

    it 'deletes more than one packages' do
      expect(project).to receive(:run).with('apk del curl python nginx', {})
      expect { plugin.remove('curl', 'python', 'nginx') }.not_to raise_error
    end

  end

  describe '#update' do
    it 'updates the package index' do
      expect(project).to receive(:run).with('apk update')
      expect { plugin.update }.not_to raise_error
    end
  end

  describe '#upgrade' do
    it 'upgrades the installed packages' do
      expect(project).to receive(:run).with('apk upgrade')
      expect { plugin.upgrade }.not_to raise_error
    end
  end

end
