
RSpec.describe Drydock::ImageRepository do
  
  describe '.all' do
    it 'completes without an error' do
      expect { described_class.all }.not_to raise_error
    end
  end

  describe '.dangling' do
    it 'completes without an error' do
      expect { described_class.dangling }.not_to raise_error
    end
  end

  describe '.each' do
    it 'returns each image' do
      described_class.each do |image|
        expect(image).to be_a(Docker::Image)
      end
    end
  end

  describe '.find_by_config' do
    let(:cmd)       { '/bin/ls -l' }
    let(:image)     { Docker::Image.create(fromImage: 'alpine', tag: 'latest') }
    let(:container) { image.run(cmd).tap(&:wait) }
    let(:run_image) { container.commit }

    after(:each) do
      container.remove
      run_image.remove
    end

    it 'returns the latest image' do
      expect(run_image.id).not_to be_nil

      build_config = Drydock::ContainerConfig.from(
        Cmd: cmd.to_s.split(/\s+/),
        Tty: false,
        Image: image.id,
        Env: nil
      )

      possible_images = described_class.select_by_config(build_config)
      expect(possible_images).not_to be_empty

      found_image = described_class.find_by_config(build_config)
      expect(found_image).not_to be_nil
      expect(found_image.id).to eq(run_image.id)
    end
  end

end
