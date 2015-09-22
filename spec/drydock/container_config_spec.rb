
# Tests taken from specs at https://github.com/docker/docker/blob/master/runconfig/compare_test.go
RSpec.describe Drydock::ContainerConfig do
  
  describe '#==' do

    let(:ports1) { {"1111/tcp" => {}, "2222/tcp" => {}} }
    let(:ports2) { {"3333/tcp" => {}, "4444/tcp" => {}} }
    let(:ports3) { {"1111/tcp" => {}, "2222/tcp" => {}, "5555/tcp" => {}} }

    let(:volumes1) { {"/test1" => {}} }
    let(:volumes2) { {"/test2" => {}} }
    let(:volumes3) { {"/test1" => {}, "/test3" => {}} }

    let(:envs1) { ["ENV1=value1", "ENV2=value2"] }
    let(:envs2) { ["ENV1=value1", "ENV3=value3"] }

    let(:entrypoint1) { ['/bin/sh', '-c'] }
    let(:entrypoint2) { ['/bin/sh', '-d'] }
    let(:entrypoint3) { ['/bin/sh', '-c', 'echo'] }

    let(:cmd1) { ['/bin/sh', '-c'] }
    let(:cmd2) { ['/bin/sh', '-d'] }
    let(:cmd3) { ['/bin/sh', '-c', 'echo'] }

    let(:labels1) { {"LABEL1" => "value1", "LABEL2" => "value2"} }
    let(:labels2) { {"LABEL1" => "value1", "LABEL2" => "value3"} }
    let(:labels3) { {"LABEL1" => "value1", "LABEL2" => "value2", "LABEL3" => "value3"} }

    context 'empty configs' do
      it_behaves_like 'the same configs' do
        let(:config1) { {} }
        let(:config2) { {} }
      end
    end

    context 'different hostnames, domain names, or image' do
      it_behaves_like 'the same configs' do
        let(:config1) {
          {
            Hostname:   "host1",
            Domainname: "domain1",
            Image:      "image1",
            User:       "user"
          }
        }
        let(:config2) {
          {
            Hostname:   "host2",
            Domainname: "domain2",
            Image:      "image2",
            User:       "user"
          }
        }
      end
    end

    context 'only OpenStdin' do
      it_behaves_like 'the same configs' do
        let(:config1) { {OpenStdin: false} }
        let(:config2) { {OpenStdin: false} }
      end
    end

    context 'only Env' do
      it_behaves_like 'the same configs' do
        let(:config1) { {Env: envs1.dup} }
        let(:config2) { {Env: envs1.dup} }
      end
    end

    context 'only Cmd' do
      it_behaves_like 'the same configs' do
        let(:config1) { {Cmd: cmd1.dup} }
        let(:config2) { {Cmd: cmd1.dup} }
      end
    end

    context 'only Labels' do
      it_behaves_like 'the same configs' do
        let(:config1) { {Labels: labels1.dup} }
        let(:config2) { {Labels: labels1.dup} }
      end
    end

    context 'only ExposedPorts' do
      it_behaves_like 'the same configs' do
        let(:config1) { {ExposedPorts: ports1.dup} }
        let(:config2) { {ExposedPorts: ports1.dup} }
      end
    end

    context 'only Entrypoint' do
      it_behaves_like 'the same configs' do
        let(:config1) { {Entrypoint: entrypoint1.dup} }
        let(:config2) { {Entrypoint: entrypoint1.dup} }
      end
    end

    context 'only Volumes' do
      it_behaves_like 'the same configs' do
        let(:config1) { {Volumes: volumes1.dup} }
        let(:config2) { {Volumes: volumes1.dup} }
      end
    end



    context 'with nil' do
      it_behaves_like 'different configs' do
        let(:config1) { {} }
        let(:config2) { nil }
      end
    end

    context 'different users' do
      it_behaves_like 'different configs' do
        let(:config1) {
          {
            Hostname:   "host1",
            Domainname: "domain1",
            Image:      "image1",
            User:       "user1"
          }
        }
        let(:config2) {
          {
            Hostname:   "host1",
            Domainname: "domain1",
            Image:      "image1",
            User:       "user2"
          }
        }
      end
    end

    context 'differing OpenStdin' do
      it_behaves_like 'different configs' do
        let(:config1) { {OpenStdin: false} }
        let(:config2) { {OpenStdin: true } }
      end
    end

    context 'differing OpenStdin, reversed' do
      it_behaves_like 'different configs' do
        let(:config1) { {OpenStdin: true } }
        let(:config2) { {OpenStdin: false} }
      end
    end

    context 'differing Env' do
      it_behaves_like 'different configs' do
        let(:config1) { {Env: envs1} }
        let(:config2) { {Env: envs2} }
      end
    end

    context 'differing Cmd' do
      it_behaves_like 'different configs' do
        let(:config1) { {Cmd: cmd1} }
        let(:config2) { {Cmd: cmd2} }
      end
    end

    context 'differing Cmd parts' do
      it_behaves_like 'different configs' do
        let(:config1) { {Cmd: cmd1} }
        let(:config2) { {Cmd: cmd3} }
      end
    end

    context 'differing Labels' do
      it_behaves_like 'different configs' do
        let(:config1) { {Labels: labels1} }
        let(:config2) { {Labels: labels2} }
      end
    end

    context 'differing Labels' do
      it_behaves_like 'different configs' do
        let(:config1) { {Labels: labels1} }
        let(:config2) { {Labels: labels3} }
      end
    end

    context 'differing ExposedPorts' do
      it_behaves_like 'different configs' do
        let(:config1) { {ExposedPorts: ports1} }
        let(:config2) { {ExposedPorts: ports2} }
      end
    end

    context 'differing number of ExposedPorts' do
      it_behaves_like 'different configs' do
        let(:config1) { {ExposedPorts: ports1} }
        let(:config2) { {ExposedPorts: ports3} }
      end
    end

    context 'differing Entrypoint' do
      it_behaves_like 'different configs' do
        let(:config1) { {Entrypoint: entrypoint1} }
        let(:config2) { {Entrypoint: entrypoint2} }
      end
    end

    context 'differing Entrypoint parts' do
      it_behaves_like 'different configs' do
        let(:config1) { {Entrypoint: entrypoint1} }
        let(:config2) { {Entrypoint: entrypoint3} }
      end
    end

    context 'differing Volumes' do
      it_behaves_like 'different configs' do
        let(:config1) { {Volumes: volumes1} }
        let(:config2) { {Volumes: volumes2} }
      end
    end

    context 'differing number of Volumes' do
      it_behaves_like 'different configs' do
        let(:config1) { {Volumes: volumes1} }
        let(:config2) { {Volumes: volumes3} }
      end
    end

  end

end
