
RSpec.describe Drydock::Plugins::Base do

  describe '.new' do

    it 'accepts a project' do
      project = double('Project')
      expect { described_class.new(project) }.not_to raise_error
    end

  end

end
