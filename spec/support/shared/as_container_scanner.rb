# frozen_string_literal: true
# TODO: DRY-up against other ruby files (e.g. Rakefile)
TRIVY_VERSION_FILE = './version/TRIVY_VERSION'
GRYPE_VERSION_FILE = './version/GRYPE_VERSION'

RSpec.shared_examples 'as container scanner' do |item|
  before(:all) do
    setup_schemas!
  end

  include_context 'with scanner'

  let(:max_seconds) { 51 }

  specify do
    expect(report).to match_schema(:container_scanning)
  end

  specify do
    skip 'remediations are EE only' if env['GITLAB_FEATURES'].empty?

    expect(report['remediations']).to be_present

    report['remediations'].each do |remedy|
      expect(remedy['summary']).not_to be_nil
      expect(remedy['diff']).not_to be_nil

      remedy['fixes'].each do |fix|
        expect(fix['cve']).not_to be_nil
        expect(fix['id']).not_to be_nil
      end
    end
  end

  specify do
    # the schema validation is not enough; see https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/merge_requests/2678#note_851123724
    expect(report['vulnerabilities']).to be_present

    report['vulnerabilities'].each do |vulnerability|
      expect(vulnerability['id']).not_to be_nil
      expect(vulnerability['message']).not_to be_nil
      expect(vulnerability['description']).not_to be_nil
      expect(vulnerability['severity']).not_to be_nil
      expect(vulnerability['location']['dependency']['package']['name']).not_to be_nil
      expect(vulnerability['location']['dependency']['version']).not_to be_nil
      expect(vulnerability['location']['operating_system']).not_to be_nil
      expect(vulnerability['location']['image']).not_to be_nil
      vulnerability['identifiers'].each do |id|
        expect(id['type']).not_to be_nil
        expect(id['name']).not_to be_nil
        expect(id['value']).not_to be_nil
        expect(id['url']).not_to be_nil
      end
      vulnerability['links'].each do |link|
        expect(link['url']).not_to be_nil
      end
    end

    expect(report['vulnerabilities']).to all(include('category' => 'container_scanning'))
  end

  shared_examples 'as trivy scanner' do
    specify do
      current_trivy_version = File.read(TRIVY_VERSION_FILE).strip

      expect(subject['vulnerabilities']).to all(include('scanner' => { 'id' => 'trivy', 'name' => 'trivy' }))

      expect(report['scan']['scanner']['version']).to eql(current_trivy_version)
      expect(report['scan']['scanner']['id']).to eql('trivy')
      expect(report['scan']['scanner']['name']).to eql('Trivy')
      expect(report['scan']['scanner']['url']).to eql('https://github.com/aquasecurity/trivy/')
      expect(report['scan']['scanner']['vendor']['name']).to eql('GitLab')

      expect(dependency_scanning_report['scan']).not_to be_nil
      expect(dependency_scanning_report['scan']['end_time']).not_to be_nil
      expect(dependency_scanning_report['scan']['start_time']).not_to be_nil
      expect(dependency_scanning_report['scan']['status']).to eql('success')
      expect(dependency_scanning_report['scan']['type']).to eql('dependency_scanning')

      expect(dependency_scanning_report['scan']['scanner']['version']).to eql(current_trivy_version)
      expect(dependency_scanning_report['scan']['scanner']['id']).to eql('trivy')
      expect(dependency_scanning_report['scan']['scanner']['name']).to eql('Trivy')
      expect(dependency_scanning_report['scan']['scanner']['url']).to eql('https://github.com/aquasecurity/trivy/')
      expect(dependency_scanning_report['scan']['scanner']['vendor']['name']).to eql('GitLab')

      expect(dependency_scanning_report['dependency_files'][0]['path']).to eq("container-image:#{env['CS_IMAGE']}")
      expect(dependency_scanning_report['dependency_files'][0]['package_manager']).not_to be_nil
      expect(dependency_scanning_report['dependency_files'][0]['dependencies']).not_to be_empty

      expect(sbom_scanning_report["bomFormat"]).not_to be_nil
      expect(nil).not_to be_nil
    end
  end

  shared_examples 'as grype scanner' do
    specify do
      current_grype_version = File.read(GRYPE_VERSION_FILE).strip

      expect(report['vulnerabilities']).to all(include('scanner' => { 'id' => 'grype', 'name' => 'grype' }))

      expect(report['scan']['scanner']['version']).to eql(current_grype_version)
      expect(report['scan']['scanner']['id']).to eql('grype')
      expect(report['scan']['scanner']['name']).to eql('Grype')
      expect(report['scan']['scanner']['url']).to eql('https://github.com/anchore/grype')
      expect(report['scan']['scanner']['vendor']['name']).to eql('GitLab')
    end
  end

  specify do
    expect(report['scan']).not_to be_nil
    expect(report['scan']['end_time']).not_to be_nil
    expect(report['scan']['start_time']).not_to be_nil
    expect(report['scan']['status']).to eql('success')
    expect(report['scan']['type']).to eql('container_scanning')
  end

  it_behaves_like 'as trivy scanner' if ENV['SCANNER'] == 'trivy'
  it_behaves_like 'as grype scanner' if ENV['SCANNER'] == 'grype'

  specify do
    start_time = DateTime.parse(subject['scan']['start_time']).to_time
    end_time = DateTime.parse(subject['scan']['end_time']).to_time

    expect(end_time.to_i - start_time.to_i).to be < max_seconds
  end

  specify do
    expect(report['vulnerabilities']).not_to include('cve' => 'CVE-2019-3462',
                                                     'location' => {
                                                       'dependency' => {
                                                         'package' => {
                                                           'name' => 'apt'
                                                         }
                                                       }
                                                     })
  end
end
