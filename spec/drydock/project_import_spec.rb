
RSpec.describe Drydock::Project do

  let(:project) { described_class.new }
  after(:each) { project.destroy!(force: true) if project }

  it 'derives a project and imports between derivations' do
    project.from('alpine')
    project.mkdir('/app/1')

    build = project.derive
    build.mkdir('/app/2')
    build.run('echo 427911 > /app/1/VERSION')
    build.run('echo 427912 > /app/2/VERSION')
    build.run('echo 427913 > /tmp/VERSION')

    app = project.derive
    app.import('/app', from: build)

    b_container = build.last_image.run('cat /tmp/VERSION')
    b_output = b_container.tap(&:wait).streaming_logs(stdout: true, stderr: true)
    b_container.remove

    expect(b_output).to eq("427913\n")

    v1_container = app.last_image.run('cat /app/2/VERSION')
    v1_output = v1_container.tap(&:wait).streaming_logs(stdout: true, stderr: true)
    v1_container.remove

    expect(v1_output).to eq("427912\n")

    v2_container = app.last_image.run('cat /tmp/VERSION')
    v2_output = v2_container.tap(&:wait).streaming_logs(stdout: true, stderr: true)
    v2_container.remove

    expect(v2_output).to include("'/tmp/VERSION': No such file or directory")
  end

end
