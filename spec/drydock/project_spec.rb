
RSpec.describe Drydock::Project do

  let(:project) { described_class.new }
  after(:each) { project.destroy!(force: true) if project }

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

  it 'autocreates the target path on copy' do
    project.from('alpine')
    expect {
      project.copy(asset_path, '/assets', chmod: false, no_cache: true, recursive: true)
    }.to raise_error(Drydock::InvalidInstructionError)

    expect(project.last_image).to be_nil
  end

  it 'downloads from the source URL once' do
    expect(Excon).to receive(:get).once.with('http://httpbin.org/ip', hash_including(:response_block))

    project.set :cache, Drydock::ObjectCaches::InMemoryCache.new
    project.from('alpine')
    expect {
      project.download_once('http://httpbin.org/ip', '/etc/ip_address.json',   chmod: 0600)
      project.download_once('http://httpbin.org/ip', '/etc/ip_address_2.json', chmod: 0600)
    }.not_to raise_error
  end

  it 'sets the raw Cmd' do
    project.from('alpine')
    project.cmd(['/bin/bash'])

    expect(project.last_image).not_to be_nil

    image = Docker::Image.get(project.last_image.id)
    expect(image).not_to be_nil
    expect(image.info['Config']['Cmd']).to eq(['/bin/bash'])
  end

  it 'sets the shell Cmd' do
    project.from('alpine')
    project.cmd('/bin/ls')

    expect(project.last_image).not_to be_nil

    image = Docker::Image.get(project.last_image.id)
    expect(image).not_to be_nil
    expect(image.info['Config']['Cmd']).to eq(['/bin/sh', '-c', '/bin/ls'])
  end

  it 'keeps the shell Cmd even after another build command' do
    project.from('alpine')
    project.cmd('/bin/ls')
    project.run('/bin/date')

    expect(project.last_image).not_to be_nil

    image = Docker::Image.get(project.last_image.id)
    expect(image).not_to be_nil
    expect(image.info['Config']['Cmd']).to eq(['/bin/sh', '-c', '/bin/ls'])
    expect(image.info['ContainerConfig']['Cmd']).to eq(['/bin/sh', '-c', '/bin/date'])
  end

  it 'sets the Env' do
    project.from('alpine')
    project.env('APP_ROOT_TEST', '/app/current')

    expect(project.last_image).not_to be_nil

    image = Docker::Image.get(project.last_image.id)
    expect(image).not_to be_nil
    expect(image.info['Config']['Env']).to include('APP_ROOT_TEST=/app/current')
  end

  it 'sets the Env with multiple values' do
    project.from('alpine')
    project.env('APP_ROOT_TEST', '/app/current')
    project.env('BUILD_ROOT',    '/tmp/build')

    expect(project.last_image).not_to be_nil

    image = Docker::Image.get(project.last_image.id)
    expect(image).not_to be_nil
    expect(image.info['Config']['Env']).to include('APP_ROOT_TEST=/app/current')
    expect(image.info['Config']['Env']).to include('BUILD_ROOT=/tmp/build')
  end

  it 'sets the ExposedPorts' do
    project.from('alpine')
    project.expose(tcp: [80, 443], udp: 53)

    expect(project.last_image).not_to be_nil

    image = Docker::Image.get(project.last_image.id)
    expect(image).not_to be_nil
    expect(image.info['Config']['ExposedPorts']).to include('80/tcp')
    expect(image.info['Config']['ExposedPorts']).to include('443/tcp')
    expect(image.info['Config']['ExposedPorts']).to include('53/udp')
  end

end
