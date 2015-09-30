
RSpec.describe Docker::Container do
  
  describe '#archive_put' do
    let(:tar) { Docker::Util.create_tar('/some_file' => 'contents_123') }
    let(:container) { described_class.create('Image' => 'alpine:latest', 'Cmd' => ['/bin/sh']) }
    let(:image) { container.commit }
    let(:run_container) { image.run(['/bin/cat', '/some_file']).tap(&:wait) }
    let(:output) { run_container.streaming_logs(stdout: true, stderr: true) }

    after(:each) { container.remove }

    context 'when given a tar stream' do
      after do
        run_container.remove
        image.remove
      end

      it 'has a file in the container' do
        container.archive_put('/') do |output|
          output.write(tar)
        end
        expect(output).to start_with('contents_123')
      end
    end
  end

  describe '#archive_get' do
    let(:container) { described_class.create('Image' => 'alpine:latest', 'Cmd' => ['/bin/touch', '/real_file']) }

    after(:each) { container.remove }

    context 'when the file does not exist' do
      it 'is not found' do
        container.start
        container.wait
        expect { container.archive_get('/not_a_file') { |c| c } }.to raise_error(Docker::Error::NotFoundError)
      end
    end

    context 'when the file is found' do
      it 'yields in chunks' do
        container.start
        container.wait

        chunks = StringIO.new
        container.archive_get('/real_file') { |c| chunks << c }
        expect(chunks.string).to start_with("real_file\0\0")
      end
    end
  end

  describe '#archive_head' do
    let(:container) { described_class.create('Image' => 'alpine:latest', 'Cmd' => ['/bin/touch', '/real_file']) }

    before(:each) { container.tap(&:start).tap(&:wait) }
    after(:each) { container.remove }

    context 'when the file does not exist' do
      it 'is not found' do
        expect(container.archive_head('/not_a_file')).to eq(nil)
      end
    end

    context 'when the file is found' do
      it 'returns the stat results' do
        stat = container.archive_head('/real_file')
        expect(stat).to be_a(Docker::ContainerPathStat)
        expect(stat.name).to eq('real_file')
        expect(stat.size).to eq(0)

        expect(stat.mode.file_mode).to eq(0644)
        expect(stat.mode.regular?).to be_truthy
        expect(stat.mode.directory?).to be_falsey

        expect(stat.mode.flags).to be_empty
        expect(stat.mode.short_flags).to be_empty
        expect(stat.mode.to_s).to eq('')

        expect(stat.mtime).not_to be_nil
      end
    end

    context 'when a link is found' do
      it 'returns the stat results' do
        stat = container.archive_head('/etc/mtab')
        expect(stat).to be_a(Docker::ContainerPathStat)
        expect(stat).to respond_to(:link?)

        expect(stat.mode.link?).to be_truthy
        expect(stat.link?).to be_truthy
        expect(stat.link_target).to eq('/proc/mounts')

        expect(stat.mode.flags).to eq([:link])
        expect(stat.mode.short_flags).to eq(['L'])
        expect(stat.mode.to_s).to eq('L')

        expect(stat.mtime).not_to be_nil
      end
    end
  end

end
