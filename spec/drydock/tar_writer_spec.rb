
RSpec.describe Drydock::TarWriter do

  describe '#add_entry' do

    let(:buffer) { StringIO.new('') }

    let(:some_time) { 1420070400 } # Jan 1, 2015 00:00:00 GMT
    let(:file1) { {name: 'test_file', contents: 'So Much Wow!', mode: 0640, mtime: Time.at(some_time)} }
    let(:file2) { {name: 'some_file', contents: "#!/bin/sh\n",  mode: 0755, mtime: Time.at(some_time)} }

    it 'creates the correct tar stream containing the correct files' do
      described_class.new(buffer) do |tar|
        [file1, file2].each do |file|
          tar.add_entry(file[:name], mode: file[:mode], mtime: file[:mtime]) do |stream|
            stream.write(file[:contents])
          end
        end
      end

      buffer.rewind
      expect(buffer.string).to eq(File.read('spec/assets/sample.tar'))
    end

  end

end
