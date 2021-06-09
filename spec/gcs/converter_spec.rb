# frozen_string_literal: true
RSpec.describe Gcs::Converter do
  let(:trivy_output_alpine) { fixture_file_content('trivy-alpine.json') }
  let(:trivy_output_centos) { fixture_file_content('trivy-centos.json') }
  let(:trivy_output_debian) { fixture_file_content('trivy-debian.json') }

  it 'converts into valid format' do
    gitlab_format = described_class.new(trivy_output_alpine, nil, {}).convert
    result = Schema::ReportSchema.call(gitlab_format)
    expect(result).to be_success
  end

  it 'converts into valid format for centos' do
    gitlab_format = described_class.new(trivy_output_centos, nil, {}).convert
    result = Schema::ReportSchema.call(gitlab_format)
    expect(result).to be_success
  end

  it 'converts into valid format for debian based images' do
    gitlab_format = described_class.new(trivy_output_debian, nil, {}).convert
    result = Schema::ReportSchema.call(gitlab_format)

    expect(result).to be_success
  end
end
