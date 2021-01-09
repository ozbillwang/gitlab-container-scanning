# frozen_string_literal: true

RSpec.shared_examples 'as container scanner' do |item|
  include_context 'with scanner'

  let(:max_seconds) { 51 }

  specify do
    expect(subject).to match_schema(:container_scanning)
  end

  specify do
    subject['remediations'].each do |remedy|
      expect(remedy['summary']).not_to be_nil
      expect(remedy['diff']).not_to be_nil

      remedy['fixes'].each do |fix|
        expect(fix['cve']).not_to be_nil
        expect(fix['id']).not_to be_nil
      end
    end
  end

  specify do
    expect(subject['vulnerabilities']).to all(include('category' => 'container_scanning'))
  end

  specify do
    expect(subject['vulnerabilities']).to all(include('scanner' => { 'id' => 'trivy', 'name' => 'trivy' }))
  end

  specify do
    subject['vulnerabilities'].each do |vulnerability|
      expect(vulnerability['id']).not_to be_nil
      expect(vulnerability['message']).not_to be_nil
      expect(vulnerability['description']).not_to be_nil
      expect(vulnerability['cve']).not_to be_nil
      expect(vulnerability['severity']).not_to be_nil
      expect(vulnerability['confidence']).not_to be_nil
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
  end

  specify do
    expect(subject['scan']).not_to be_nil
    expect(subject['scan']['end_time']).not_to be_nil
    expect(subject['scan']['scanner']['id']).to eql('trivy')
    expect(subject['scan']['scanner']['name']).to eql('Trivy')
    expect(subject['scan']['scanner']['url']).to eql('https://github.com/aquasecurity/trivy/')
    expect(subject['scan']['scanner']['vendor']['name']).to eql('GitLab')
    expect(subject['scan']['scanner']['version']).to eql('0.13.0')
    expect(subject['scan']['start_time']).not_to be_nil
    expect(subject['scan']['status']).to eql('success')
    expect(subject['scan']['type']).to eql('container_scanning')
  end

  specify do
    start_time = DateTime.parse(subject['scan']['start_time']).to_time
    end_time = DateTime.parse(subject['scan']['end_time']).to_time

    expect(end_time.to_i - start_time.to_i).to be < max_seconds
  end
end
