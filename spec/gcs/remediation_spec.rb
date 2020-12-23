
RSpec.describe Gcs::Remediation do
    let(:docker_file_path) { fixture_file('docker/remediation-Dockerfile') }

    let(:remediation) {
        described_class.new({
        'package_name' => 'curl',
        'package_version' => '2.0.0',
        'fixed_version' => '2.2.1',
        'operating_system' => 'centos',
        'summary' => 'Upgrade curl to 2.2.1'
    }, docker_file_path)
    }


    it 'works' do
        a= 1
        remediation.to_hash
    end
end
