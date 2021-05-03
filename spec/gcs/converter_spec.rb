# frozen_string_literal: true
# rubocop: disable RSpec/LeakyConstantDeclaration
# rubocop: disable Lint/ConstantDefinitionInBlock
RSpec.describe Gcs::Converter do
  let(:trivy_output_alpine) { fixture_file_content('trivy-alpine.json') }
  let(:trivy_output_centos) { fixture_file_content('trivy-centos.json') }
  let(:trivy_output_debian) { fixture_file_content('trivy-debian.json') }

  IdentifierSchema = Dry::Schema.JSON do
    required(:type).filled(:string)
    required(:name).filled(:string)
    required(:value).filled(:string)
    required(:url)
  end

  FixesSchema = Dry::Schema.JSON do
    required(:cve).filled(:string)
    required(:id).filled(:string)
  end

  RemediationSchema = Dry::Schema.JSON do
    required(:fixes).array(FixesSchema)
    required(:summary).filled(:string)
    required(:diff).filled(:string)
  end

  VulnerabilitySchema = Dry::Schema.JSON do
    required(:id).filled(:string)
    required(:category).value(eql?: 'container_scanning')
    optional(:message)
    required(:description).filled(:string)
    required(:cve).filled(:string)
    required(:severity).filled(:string)
    required(:confidence).filled(:string)
    required(:solution).filled(:str?)
    required(:scanner).hash do
      required(:id).filled(:string)
      required(:name).filled(:string)
    end
    required(:location).hash do
      required(:dependency).hash do
        required(:package).hash do
          required(:name).filled(:string)
        end
        required(:version).filled(:string)
      end
      required(:operating_system).filled(:string)
      required(:image).filled(:string).value(format?: /(.{1,}:[0-9a-f]{32,128}\z|\w{1,})/)
    end
    required(:identifiers).array(IdentifierSchema)
    required(:links)
  end

  schema = Dry::Schema.JSON do
    required(:version).filled(:string)
    required(:vulnerabilities).array(VulnerabilitySchema)
    required(:remediations).array(RemediationSchema)
  end

  it 'converts into valid format' do
    gitlab_format = described_class.new(trivy_output_alpine, nil, {}).convert
    result = schema.call(gitlab_format)
    expect(result).to be_success
  end

  it 'converts into valid format for centos' do
    gitlab_format = described_class.new(trivy_output_centos, nil, {}).convert
    result = schema.call(gitlab_format)
    expect(result).to be_success
  end

  it 'converts into valid format for debian based images' do
    gitlab_format = described_class.new(trivy_output_debian, nil, {}).convert
    result = schema.call(gitlab_format)

    expect(result).to be_success
  end
end
# rubocop: enable RSpec/LeakyConstantDeclaration
# rubocop: enable Lint/ConstantDefinitionInBlock
