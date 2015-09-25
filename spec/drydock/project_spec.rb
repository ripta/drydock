
RSpec.describe Drydock::Project do

  let(:project) { described_class.new }
  after(:each) { project.destroy! if project }

  let(:asset_path) { 'spec/assets' }

  it 'require a `from` before a `run`' do
    expect { project.run('ls /') }.to raise_error(Drydock::InvalidInstructionError)
  end

  it 'require only one `from` per project' do
    expect { project.from('alpine') }.not_to raise_error
    expect { project.from('alpine') }.to raise_error(Drydock::InvalidInstructionError)
  end

  it 'sets no extra information on image commit' do
    expect { project.from('alpine') }.not_to raise_error
    expect { project.run('ls /')    }.not_to raise_error

    image = Docker::Image.get(project.last_image.id)
    expect(image).not_to be_nil
    expect(image.info['Author']).to eq('')
  end

  it 'sets the author after an image commit' do
    name = 'John Doe'
    email = 'john@doe.int'
    author = 'John Doe <john@doe.int>'

    project.from('alpine')
    project.author(name: name, email: email)

    expect { project.run('ls /') }.not_to raise_error
    expect(project.last_image).not_to be_nil

    image = Docker::Image.get(project.last_image.id)
    expect(image).not_to be_nil
    expect(image.info['Author']).to eq(author)
  end

  it 'build ID is incremented at every build step' do
    expect(project.build_id).to eq('0')

    project.from('alpine')
    expect(project.build_id).to eq('1')
  end

  it 'copies asset files into an image' do
    project.from('alpine')
    expect { project.copy(asset_path, '/', chmod: false, no_cache: true, recursive: true) }.not_to raise_error

    expect(project.last_image).not_to be_nil
    expect(project.last_image.id).not_to be_empty

    hash_container = project.last_image.run('sha1sum /spec/assets/hello-world.txt')
    hash_output = hash_container.tap(&:wait).streaming_logs(stdout: true, stderr: true)
    hash_container.remove

    expect(hash_output).to include('60fde9c2310b0d4cad4dab8d126b04387efba289')
  end

end
