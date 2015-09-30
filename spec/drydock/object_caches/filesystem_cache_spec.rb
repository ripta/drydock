
RSpec.describe Drydock::ObjectCaches::FilesystemCache do
  include FakeFS::SpecHelpers # mock the filesystem
  
  describe '.new' do
    it 'can take zero or one argument' do
      expect { described_class.new }.not_to raise_error
      expect { described_class.new("/tmp/drydock-spec") }.not_to raise_error
    end

    it 'creates the cache directory' do
      described_class.new("/tmp/drydock-spec")
      expect(File.exist?("/tmp/drydock-spec/cache")).to eq(true)
    end
  end

  describe '#fetch' do
    let(:cache) { described_class.new("/tmp/drydock-spec") }

    it 'uses an existing value, when one is already set' do
      cache.set('hello_world', 'Hello, World!')
      expect(cache.fetch('hello_world') { 'Backup Value' }).to eq('Hello, World!')
    end

    it 'invokes the writer if no value is already set' do
      expect(cache.fetch('hello_world') { 'Backup Value' }).to eq('Backup Value')
    end
  end

  describe '#get, #set' do
    let(:cache) { described_class.new("/tmp/drydock-spec") }

    context 'when used in value form' do
      it 'persists the cache entry' do
        expect { cache.set('hello_world', 'Hello, World!') }.not_to raise_error
        expect(cache.get('hello_world')).to eq('Hello, World!')
      end
    end

    context 'when used in block form' do
      it 'persists the cache entry' do
        expect { cache.set('bye_world') { |f| f.write 'Goodbye, World!' } }.not_to raise_error
        expect(cache.get('bye_world')).to eq('Goodbye, World!')
      end
    end
  end

end
