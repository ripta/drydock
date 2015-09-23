
RSpec.describe Drydock::Project do

  let(:project) { described_class.new }
  after(:each)  { project.destroy! }

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

    expect { project.from('alpine')                   }.not_to raise_error
    expect { project.author(name: name, email: email) }.not_to raise_error
    expect { project.run('ls /')                      }.not_to raise_error

    expect(project.last_image).not_to be_nil

    image = Docker::Image.get(project.last_image.id)
    expect(image).not_to be_nil
    expect(image.info['Author']).to eq(author)
  end

  it 'build ID is incremented at every build step' do
    expect(project.build_id).to eq('0')

    expect { project.from('alpine') }.not_to raise_error
    expect(project.build_id).to eq('1')
  end

end
