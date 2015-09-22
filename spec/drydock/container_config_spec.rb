
# Tests taken from specs at https://github.com/docker/docker/blob/master/runconfig/compare.go
RSpec.describe Drydock::ContainerConfig do
  
  describe '#==' do

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

  end

end
