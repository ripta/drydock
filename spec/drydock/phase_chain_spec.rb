
RSpec.describe Drydock::PhaseChain do

  describe '.from_repo' do

    it 'takes a repo name forced without a tag' do
      expect { described_class.from_repo('alpine', nil) }.not_to raise_error
    end

    it 'takes a repo name without a tag' do
      expect { described_class.from_repo('alpine') }.not_to raise_error
    end

    it 'takes a repo name and tag' do
      expect { described_class.from_repo('alpine', 'latest') }.not_to raise_error
    end

  end

  describe '#root_image' do

    subject { described_class.from_repo('alpine', '3.2').root_image }

    it 'returns the image object' do
      expect(subject).to be_a(Docker::Image)
    end

    it 'matches the image tag' do
      expect(subject.info).not_to be_nil

      # Docker Remote API v1.21 introduced RepoTags
      if subject.info.key?('RepoTags')
        expect(subject.info['RepoTags']).to include('alpine:3.2')
      end
    end

  end

  describe '#images' do

    let(:chain) { described_class.from_repo('alpine', '3.2') }
    subject { chain.images }

    it 'returns only the root object' do
      expect(subject).to eq([chain.root_image])
    end

  end

  describe '#last_image' do

    let(:chain) { described_class.from_repo('alpine', '3.2') }
    subject { chain.last_image }
    it { is_expected.to be_nil }

  end

  describe '#run' do

    let(:chain) { described_class.from_repo('alpine', '3.2') }

    it 'runs a simple command successfully' do
      expect(chain.images.size).to eq(1)
      expect { chain.run('/bin/hostname') }.not_to raise_error
      expect(chain.images.size).to eq(2)
      expect { chain.destroy! }.not_to raise_error
    end

    it 'runs a command without committing successfully' do
      expect(chain.images.size).to eq(1)
      expect { chain.run('/bin/hostname', no_commit: true) }.not_to raise_error
      expect(chain.images.size).to eq(1)
      expect { chain.destroy! }.not_to raise_error
    end

    it 'sets a comment or author when provided' do
      expect { chain.run('/bin/hostname', comment: 'Some random comment', author: 'John Doe') }.not_to raise_error
      chain.last_image.tap do |image|
        image.refresh!
        expect(image.info['Comment']).to eq('Some random comment')
        expect(image.info['Author']).to eq('John Doe')
      end
      expect { chain.destroy! }.not_to raise_error
    end

    it 'sets a command' do
      expect { chain.run('/bin/hostname', command: ['/bin/ls', '/']) }.not_to raise_error
      chain.last_image.tap do |image|
        image.refresh!
        expect(image.info['Config']['Cmd']).to eq(['/bin/ls', '/'])
      end
      expect { chain.destroy! }.not_to raise_error
    end

    it 'sets an environment' do
      expect { chain.run('/bin/hostname', env: ["APP_ROOT=/app", "BUILD_ROOT=/build"]) }.not_to raise_error
      chain.last_image.tap do |image|
        image.refresh!
        expect(image.info['Config']['Env']).to include('APP_ROOT=/app')
        expect(image.info['Config']['Env']).to include('BUILD_ROOT=/build')
      end
      expect { chain.destroy! }.not_to raise_error
    end

    it 'exposes a port' do
      expect { chain.run('/bin/hostname', expose: ['80/tcp']) }.not_to raise_error
      chain.last_image.tap do |image|
        image.refresh!
        expect(image.info['Config']['ExposedPorts']).to eq("80/tcp" => {})
      end
      expect { chain.destroy! }.not_to raise_error
    end

  end

end
