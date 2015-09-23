
RSpec.describe Drydock::RuntimeOptions do

  describe '.parse!' do
    it 'accepts build options' do
      opts = described_class.parse!(%w{--no-cache -i test.rb -q})
      expect(opts.cache).to be_falsey
      expect(opts.includes).to include('test.rb')
      expect(opts.log_level).to eq(Logger::ERROR)
    end

    it 'accepts extra build arguments' do
      opts = described_class.parse!(%w{--build-opts version=2.0.3 --build-opts validate=true})

      expect(opts.build_opts['version']).to eq('2.0.3')
      expect(opts.build_opts[:version]).to  eq('2.0.3')
      expect(opts.build_opts[:validate]).to eq('true')
    end

    it 'converts timeout to integer' do
      opts = described_class.parse!(%w{--timeout 20})
      expect(opts.read_timeout).to eq(20)
    end

    it 'allows one to enable debug mode' do
      opts = described_class.parse!(%w{--verbose})
      expect(opts.log_level).to eq(Logger::DEBUG)
    end
  end

end
