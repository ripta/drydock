
RSpec.describe Drydock::StreamMonitor do
  let(:events)  { Array.new }
  let(:handler) { lambda { |evt, is_new, serial, evt_type| events << evt } }
  let(:monitor) { described_class.new(handler) }

  after(:each) do
    monitor.kill
    monitor.join
  end

  describe '#alive?' do
    subject { monitor.alive? }
    it { is_expected.to be_truthy }
  end

  describe 'scenario' do
    let(:image) { Docker::Image.create(fromImage: 'alpine', tag: 'latest') }
    let(:container) { image.run('ls -l').tap(&:wait) }
    let(:run_image) { container.commit }

    after(:each) do
      container.remove
      run_image.remove
    end

    it 'receives the precise number of events', broken_before_d18: true do
      expect(events).to have(0).items

      expect(monitor).not_to be_nil
      expect(run_image).not_to be_nil

      sleep 2
      expect(events).to have_at_least(1).item

      event_statuses = events.map(&:status).sort
      expect(event_statuses).to include('create')
      expect(event_statuses).to include('pull')
      expect(event_statuses).to include('start')

      commit_event = events.find { |evt| evt.status == 'commit' }
      expect(commit_event).not_to be_nil
      expect(commit_event.id).to eq(container.id)
    end
  end

end
