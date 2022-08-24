# frozen_string_literal: true
RSpec.describe Gcs::Environment do
  let(:commit_sha) { '85cbadce93fec0d78225fc00897221d8a74cb1f9' }
  let(:ci_registry_image) { 'registry.gitlab.com/defen/trivy-test' }
  let(:ci_commit_ref_slug) { 'master' }
  let(:custom_docker_file_path) { 'CustomDocker' }
  let(:docker_file_path) { "#{described_class.project_dir}/Dockerfile" }

  describe '.docker_image' do
    it 'uses given CS_IMAGE env variable' do
      with_modified_environment 'CS_IMAGE' => 'alpine:latest' do
        allow(described_class).to receive(:default_docker_image)

        expect(described_class.docker_image).to eq('alpine:latest')
        expect(described_class).not_to have_received(:default_docker_image)
      end
    end

    context 'when CS_IMAGE env variable is not given' do
      it 'returns default_docker_image' do
        with_modified_environment 'CS_IMAGE' => nil, 'DOCKER_IMAGE' => nil do
          allow(described_class).to receive(:default_docker_image).and_return(ci_registry_image)

          expect(described_class.docker_image).to eq(ci_registry_image)
          expect(described_class).to have_received(:default_docker_image).once
        end
      end
    end
  end

  describe '.default_docker_image' do
    it 'uses CI_APPLICATION_REPOSITORY and CI_APPLICATION_TAG' do
      with_modified_environment 'CI_APPLICATION_REPOSITORY' => 'ghcr.io/aquasecurity/trivy',
                                'CI_APPLICATION_TAG' => 'latest' do
        expect(described_class.default_docker_image).to eq('ghcr.io/aquasecurity/trivy:latest')
      end
    end

    context 'when CS_IMAGE and CI_APPLICATION_REPOSITORY are empty' do
      modify_environment 'CS_IMAGE' => nil,
                         'CI_APPLICATION_REPOSITORY' => nil,
                         'CI_COMMIT_REF_SLUG' => 'master',
                         'CI_REGISTRY_IMAGE' => 'registry.gitlab.com/defen/trivy-test'

      it 'uses CI_REGISTRY_IMAGE and CI_COMMIT_REF_SLUG' do
        with_modified_environment 'CI_APPLICATION_TAG' => 'latest' do
          expect(described_class.default_docker_image).to eq('registry.gitlab.com/defen/trivy-test/master:latest')
        end
      end

      it 'uses CI_COMMIT_SHA' do
        image = 'registry.gitlab.com/defen/trivy-test/master:85cbadce93fec0d78225fc00897221d8a74cb1f9'

        with_modified_environment 'CI_COMMIT_SHA' => commit_sha do
          expect(described_class.default_docker_image).to eq(image)
        end
      end
    end

    describe '#severity_level_name' do
      it 'returns value for given severity level' do
        with_modified_environment 'CS_SEVERITY_THRESHOLD' => 'low' do
          expect(described_class.severity_level_name).to eq("LOW")
        end
      end

      it 'returns unknown for nil value' do
        with_modified_environment 'CS_SEVERITY_THRESHOLD' => nil do
          expect(described_class.severity_level_name).to eq("UNKNOWN")
        end
      end
    end

    context 'with dockerfile present' do
      before do
        allow_any_instance_of(Pathname).to receive(:exist?).and_return(true)
      end

      it 'uses dockerfile path variable for remediations' do
        with_modified_environment 'CS_DOCKERFILE_PATH' => custom_docker_file_path do
          expect(described_class.docker_file.to_s).to eq(custom_docker_file_path)
        end
      end

      it 'uses default value for dockerfile path' do
        expect(described_class.docker_file.to_s).to eq(docker_file_path)
      end
    end

    context 'with dockerfile not present' do
      before do
        allow_any_instance_of(Pathname).to receive(:exist?).and_return(false)
      end

      it 'does not process the remediations', pending: 'What should be the expected behavior here?' do
        expect(Gcs.logger).to receive(:error)
        expect(described_class.docker_file.exist?).to be false
      end
    end

    context 'when required variables are not set' do
      modify_environment 'CI_COMMIT_REF_SLUG' => 'master',
                         'CI_REGISTRY_IMAGE' => 'registry.gitlab.com/defen/trivy-test',
                         'CI_COMMIT_SHA' => '85cbadce93fec0d78225fc00897221d8a74cb1f9'

      where(:missing_variable) { %w[CI_COMMIT_REF_SLUG CI_REGISTRY_IMAGE CI_COMMIT_SHA] }

      with_them do
        it 'exits the program' do
          with_modified_environment missing_variable => nil do
            expect(Gcs.logger).to receive(:error)
            execution = -> { described_class.default_docker_image }
            expect(execution).to terminate.with_code(1)
          end
        end
      end
    end
  end

  describe '.setup' do
    where(:log_level) do
      %w[debug info warn error fatal]
    end

    with_them do
      it 'sets the Gcs logger level' do
        with_modified_environment 'SECURE_LOG_LEVEL' => log_level do
          described_class.setup

          expect(Gcs.logger.public_send("#{log_level}?")).to be_truthy
        end
      end
    end
  end

  describe '.project_dir' do
    modify_environment 'CI_PROJECT_DIR' => 'gitlab/my_project'

    it 'returns current directory if given project path doesn\'t exists' do
      expect(described_class.project_dir).to eq(Pathname.pwd)
    end
  end

  describe '.docker_registry_credentials' do
    context 'with default CI credentials set' do
      modify_environment 'CS_REGISTRY_USER' => nil,
                         'CS_REGISTRY_PASSWORD' => nil,
                         'CI_REGISTRY_USER' => 'some registry user',
                         'CI_REGISTRY_PASSWORD' => 'a registry password'

      context 'with Docker credentials not configured' do
        let(:ci_registry) { 'registry.gitlab.example.com' }
        let(:external_registry_image) { "external.registry.gitlab.example.com/some-image" }

        modify_environment 'CI_REGISTRY' => 'registry.gitlab.example.com'

        context 'with Gitlab registry' do
          let(:internal_registry_image) { "registry.gitlab.example.com/some-image" }

          it 'uses default credentials' do
            allow(described_class).to receive(:docker_image).and_return(internal_registry_image)

            credentials = described_class.docker_registry_credentials

            expect(credentials).not_to be_nil
            expect(credentials['username']).to eq('some registry user')
            expect(credentials['password']).to eq('a registry password')
          end
        end

        context 'with an external registry' do
          it 'does not use default credentials' do
            allow(described_class).to receive(:docker_image).and_return(external_registry_image)

            expect(described_class.docker_registry_credentials).to be_nil
          end
        end

        context 'with external registry similar to Gitlab registry' do
          let(:external_similar_registry_image) { "#{ci_registry}.anotherdomain.com/some-image" }

          it 'does not use default credentials' do
            allow(described_class).to receive(:docker_image).and_return(external_similar_registry_image)

            expect(described_class.docker_registry_credentials).to be_nil
          end
        end
      end

      context 'with Docker credentials configured' do
        let(:docker_user) { 'some Docker user' }
        let(:docker_password) { 'a Docker password' }

        it 'returns configured Docker credentials' do
          with_modified_environment 'CS_REGISTRY_USER' => docker_user, 'CS_REGISTRY_PASSWORD' => docker_password do
            expect(described_class.docker_registry_credentials).to include('username' => docker_user,
                                                                           'password' => docker_password)
          end
        end
      end
    end

    context 'with default CI credentials missing' do
      modify_environment 'CS_IMAGE' => 'registry.example.com/image',
                         'CI_REGISTRY' => 'registry.example.com',
                         'CI_REGISTRY_USER' => nil,
                         'CI_REGISTRY_PASSWORD' => nil

      it 'returns nil credentials' do
        expect(described_class.docker_registry_credentials).to eq(nil)
      end
    end
  end

  describe '.scanner' do
    context 'with SCANNER set to trivy' do
      it 'returns GCS::Trivy' do
        with_modified_environment 'SCANNER' => 'trivy' do
          expect(described_class.scanner.new).to be_an_instance_of Gcs::Trivy
        end
      end
    end

    context 'with SCANNER set to grype' do
      it 'returns GCS::Grype' do
        with_modified_environment 'SCANNER' => 'grype' do
          expect(described_class.scanner.new).to be_an_instance_of Gcs::Grype
        end
      end
    end

    context 'with an invalid SCANNER' do
      it 'throws an error' do
        with_modified_environment 'SCANNER' => 'clair' do
          expect { described_class.scanner }.to raise_error(SystemExit)
        end
      end
    end
  end

  describe '.fips_enabled?' do
    context 'with CI_GITLAB_FIPS_MODE set to false' do
      it 'returns false' do
        with_modified_environment 'CI_GITLAB_FIPS_MODE' => 'false' do
          expect(described_class.fips_enabled?).to eq(false)
        end
      end
    end

    context 'with CI_GITLAB_FIPS_MODE set to true' do
      it 'returns true' do
        with_modified_environment 'CI_GITLAB_FIPS_MODE' => 'true' do
          expect(described_class.fips_enabled?).to eq(true)
        end
      end
    end

    context 'with CI_GITLAB_FIPS_MODE is not set' do
      it 'returns false' do
        expect(described_class.fips_enabled?).to eq(false)
      end
    end
  end

  describe '.dependency_scan_disabled?' do
    context 'with CS_DISABLE_DEPENDENCY_LIST set to false' do
      it 'returns false' do
        with_modified_environment 'CS_DISABLE_DEPENDENCY_LIST' => 'false' do
          expect(described_class.dependency_scan_disabled?).to eq(false)
        end
      end
    end

    context 'with CS_DISABLE_DEPENDENCY_LIST set to true' do
      it 'returns true' do
        with_modified_environment 'CS_DISABLE_DEPENDENCY_LIST' => 'true' do
          expect(described_class.dependency_scan_disabled?).to eq(true)
        end
      end
    end

    context 'with CS_DISABLE_DEPENDENCY_LIST is not set' do
      it 'returns false' do
        expect(described_class.dependency_scan_disabled?).to eq(false)
      end
    end
  end

  describe '.ignore_unfixed_vulnerabilities?' do
    context 'with CS_IGNORE_UNFIXED set to false' do
      it 'returns false' do
        with_modified_environment 'CS_IGNORE_UNFIXED' => 'false' do
          expect(described_class.ignore_unfixed_vulnerabilities?).to eq(false)
        end
      end
    end

    context 'with CS_IGNORE_UNFIXED set to true' do
      it 'returns true' do
        with_modified_environment 'CS_IGNORE_UNFIXED' => 'true' do
          expect(described_class.ignore_unfixed_vulnerabilities?).to eq(true)
        end
      end
    end

    context 'with CS_IGNORE_UNFIXED is not set' do
      it 'returns false' do
        expect(described_class.ignore_unfixed_vulnerabilities?).to eq(false)
      end
    end
  end

  describe '.language_specific_scan_disabled?' do
    context 'with CS_DISABLE_LANGUAGE_VULNERABILITY_SCAN set to false' do
      it 'returns false' do
        with_modified_environment 'CS_DISABLE_LANGUAGE_VULNERABILITY_SCAN' => 'false' do
          expect(described_class.language_specific_scan_disabled?).to eq(false)
        end
      end
    end

    context 'with CS_DISABLE_LANGUAGE_VULNERABILITY_SCAN set to true' do
      it 'returns true' do
        with_modified_environment 'CS_DISABLE_LANGUAGE_VULNERABILITY_SCAN' => 'true' do
          expect(described_class.language_specific_scan_disabled?).to eq(true)
        end
      end
    end

    context 'with CS_DISABLE_LANGUAGE_VULNERABILITY_SCAN is not set' do
      it 'returns false' do
        expect(described_class.language_specific_scan_disabled?).to eq(true)
      end
    end
  end

  describe '.ee?' do
    context 'with GITLAB_FEATURES containing container_scanning' do
      it 'returns true' do
        with_modified_environment 'GITLAB_FEATURES' => 'container_scanning,sast,dast' do
          expect(described_class.ee?).to eq(true)
        end
      end
    end

    context 'with GITLAB_FEATURES not containing container_scanning' do
      it 'returns false' do
        with_modified_environment 'GITLAB_FEATURES' => 'sast,dast' do
          expect(described_class.ee?).to eq(false)
        end
      end
    end
  end

  describe '.default_branch_image' do
    modify_environment 'CI_REGISTRY_IMAGE' => 'registry.gitlab.com/defen/trivy-test',
                       'CI_DEFAULT_BRANCH' => 'main',
                       'CI_APPLICATION_TAG' => 'latest'

    context 'when environment variable is set' do
      let(:default_branch_image) { 'alpine:latest' }

      it 'returns the variable value' do
        with_modified_environment 'CS_DEFAULT_BRANCH_IMAGE' => default_branch_image do
          expect(described_class.default_branch_image).to eq(default_branch_image)
        end
      end
    end

    context 'when environment variable is unset' do
      it 'returns nil' do
        with_modified_environment 'CS_DEFAULT_BRANCH_IMAGE' => nil do
          expect(described_class.default_branch_image).to be_nil
        end
      end
    end

    context 'without some of the variables from gitlab integration' do
      where(:missing_variable) { %w[CI_DEFAULT_BRANCH CI_REGISTRY_IMAGE] }

      with_them do
        it 'returns nil' do
          with_modified_environment missing_variable => nil do
            expect(described_class.default_branch_image).to be_nil
          end
        end
      end
    end
  end
end
