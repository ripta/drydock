
RSpec.describe Drydock::FileManager do

  describe '.find' do

    let(:ignore_none) do
      double('Ignore Nothing').tap do |file|
        allow(file).to receive(:match?).and_return(false)
      end
    end

    context 'current directory with default options' do
      subject { described_class.find('.', ignore_none) }

      it { is_expected.to respond_to(:each) }
      it { is_expected.to include('bin/drydock') }
      it { is_expected.to have_at_least(30).items }
    end

    context 'a subdirectory' do
      context 'with default options' do
        subject { described_class.find('spec/assets', ignore_none) }
        it { is_expected.to include('MANIFEST') }
      end

      context 'with prepend path' do
        subject { described_class.find('spec/assets', ignore_none, prepend_path: true) }
        it { is_expected.to include('spec/assets/MANIFEST') }
      end

      context 'with trailing slashes with prepend path' do
        subject { described_class.find('spec/assets/', ignore_none, prepend_path: true) }
        it { is_expected.to include('spec/assets/MANIFEST') }
      end
    end

    context 'an absolute path' do
      context 'with default options' do
        let(:abs_path) { File.expand_path('spec/assets') }
        subject { described_class.find(abs_path, ignore_none) }
        it { is_expected.to include('MANIFEST') }
      end

      context 'with prepend path' do
        let(:abs_path) { File.expand_path('spec/assets') }
        subject { described_class.find(abs_path, ignore_none, prepend_path: true) }
        it { is_expected.to include(abs_path + '/MANIFEST') }
      end
    end

  end

end
