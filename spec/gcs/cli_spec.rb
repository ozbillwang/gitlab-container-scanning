# frozen_string_literal: true

RSpec.describe Gcs::Cli do
  let(:execution) { -> { described_class.start(arguments) } }
  let(:container_scan_status) { instance_double(Process::Status, success?: true) }
  let(:dependency_scan_status) { instance_double(Process::Status, success?: true) }

  before do
    allow_any_instance_of(Gcs::Plugin::ContainerScan).to receive(:scan)
      .and_return([nil, nil, container_scan_status])
    allow_any_instance_of(Gcs::Plugin::DependencyScan).to receive(:scan)
      .and_return([nil, nil, dependency_scan_status])
    allow_any_instance_of(Gcs::Plugin::ContainerScan).to receive(:convert)
    allow_any_instance_of(Gcs::Plugin::DependencyScan).to receive(:convert)
  end

  describe '#scan' do
    let(:arguments) { ['scan', 'ubuntu:latest'] }

    context 'when all scans were successful' do
      it 'does not terminate' do
        expect(execution).not_to terminate
      end
    end

    context 'when a scan was skipped' do
      before do
        allow_any_instance_of(Gcs::Plugin::DependencyScan).to receive(:enabled?).and_return(false)
        allow_any_instance_of(Gcs::Plugin::DependencyScan).to receive(:skip).and_return(nil)
      end

      it 'is treated as a success' do
        expect(execution).not_to terminate
      end
    end

    context 'when one or more scans were not successful' do
      let(:container_scan_status) { instance_double(Process::Status, success?: false) }

      it 'exits with code 1' do
        expect(execution).to terminate.with_code(1)
      end
    end
  end

  describe '#db_check' do
    let(:arguments) { ['db-check'] }
    let(:db_outdated) { true }

    before do
      allow(Gcs::Environment.scanner).to receive(:db_updated_at)
      allow(Gcs::Util).to receive(:db_outdated?).and_return(db_outdated)
    end

    context 'when DB is outdated' do
      it 'exits with code 1' do
        expect(execution).to terminate.with_code(1)
      end
    end

    context 'when DB is not outdated' do
      let(:db_outdated) { false }

      it 'does not terminate' do
        expect(execution).not_to terminate
      end
    end
  end
end
