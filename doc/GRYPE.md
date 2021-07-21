# Grype

This document contains information to help maintain [Grype](https://github.com/anchore/grype) as a [scanner](https://about.gitlab.com/handbook/engineering/development/secure/glossary-of-terms/#scanner) that's integrated into the Container Scanning [analyzer](https://about.gitlab.com/handbook/engineering/development/secure/glossary-of-terms/#analyzer).

## Reporting a bug in Grype

If you discover a problem with Grype itself (as opposed to the integration of Grype into Container Scanning), please report the bug. To do so, follow these steps:

1. Go to https://github.com/anchore/grype/issues/new/choose.

1. Find the "Bug report" choice and click "Get Started".

1. Give the issue a descriptive title, and follow the template for the issue description. Please provide as much information as possible, with reproduction steps that **anyone would be able to follow** to consistently reproduce the bug.

1. Click "Submit new issue".

## Updating Grype to the latest version

New releases of Grype are published frequently. These releases fix bugs, improve vulnerability matching, add new features, etc. In order to maximize the value delivered by the Grype scanner option to GitLab users, it's best that the GitLab integration is using as recent a Grype version as possible.

### Finding the latest version

Grype releases are listed on GitHub, and the most recent release appears first: https://github.com/anchore/grype/releases.

### Making the updates

To update Grype within the context of this GitLab integration, follow these steps:

1. Set the content of [`GRYPE_VERSION`](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/blob/master/version/GRYPE_VERSION) to the new version. Use the format `0.13.0`, rather than `v0.13.0` or `0.13`.

1. The version is also referenced within the template ([`gitlab.grype.tpl`](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/blob/master/lib/gitlab.grype.tpl)) that Grype processes to generate result data in the GitLab format. Specifically, the version string is specified within the JSON object at `.scan.scanner.version`. Set this value using the same format used in the step above.

1. Determine if the interface points between the Container Scanning code are still compatible with the version of Grype to which you're upgrading. You should be able to confirm compatibility using the existing tests (see the project's [developer documentation](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/blob/master/doc/DEVELOPING.md#running-tests-within-docker-container) to learn how to run the tests). For context, there are two notable interface points between Container Scanning and Grype itself:

   - the [`scan_image`](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/blob/730503eea60fce72b7370bda84d4c83c82638581/lib/gcs/grype.rb#L6) method that calls the Grype binary
   - the [template file](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/blob/master/lib/gitlab.grype.tpl) mentioned in the previous step, which is processed by Grype and used to produce output data that's fed back into the Container Scanning codebase

1. Ensure that any tests that expect a particular version of Grype are updated to expect the new version. (Example instances of this include: [`./spec/support/shared/as_container_scanner.rb`](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/blob/master/spec/support/shared/as_container_scanner.rb#L66), [`./spec/gcs/grype_spec.rb`](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/blob/master/spec/gcs/grype_spec.rb#L9).)

1. Open a Merge Request with these updates in the [`container-scanning` project](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning).

## Contacting the Grype maintainers

Additionally, if you'd like to talk with the maintainers of Grype, such as to ask a question, join [Anchore's community Slack workspace](https://anchore.com/slack), and post a message in the `#grype-help` channel.
