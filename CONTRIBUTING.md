## Developer Certificate of Origin + License

## Contributor License Agreement and Developer Certificate of Origin

Contributions to this repository are subject to the [Developer Certificate of Origin](https://docs.gitlab.com/ee/legal/developer_certificate_of_origin.html#developer-certificate-of-origin-version-11), or the [Individual](https://docs.gitlab.com/ee/legal/individual_contributor_license_agreement.html) or [Corporate](https://docs.gitlab.com/ee/legal/corporate_contributor_license_agreement.html) Contributor License Agreement, depending on where the contribution is made and on whose behalf:

- By submitting code contributions as an individual to the [`/ee` subdirectory](/ee) of this repository, you agree to the [Individual Contributor License Agreement](https://docs.gitlab.com/ee/legal/individual_contributor_license_agreement.html).

- By submitting code contributions on behalf of a corporation to the [`/ee` subdirectory](/ee) of this repository, you agree to the [Corporate Contributor License Agreement](https://docs.gitlab.com/ee/legal/corporate_contributor_license_agreement.html).

- By submitting code contributions as an individual or on behalf of a corporation to any directory in this repository outside of the [`/ee` subdirectory](/ee), you agree to the [Developer Certificate of Origin](https://docs.gitlab.com/ee/legal/developer_certificate_of_origin.html#developer-certificate-of-origin-version-11).

_This notice should stay as the first item in the CONTRIBUTING.md file._

## Project License

You can view this projects license in [LICENSE.md](LICENSE)

## Contributor Resources

Thank you for your interest in contributing to GitLab. 

For a first-time step-by-step guide to the contribution process, see our
[Contributing to GitLab](https://about.gitlab.com/community/contribute/) page.

You may also find these resources useful: 
- [Documentation for community contributions](https://docs.gitlab.com/ee/development/contributing/#contribute-to-gitlab) 
- [Security Scanner documentation](https://docs.gitlab.com/ee/development/integrations/secure.html) 

For more details, see the [development guide](./doc/DEVELOPING.md).

### Issue tracker

To get support for your particular problem please use the
[getting help channels](https://about.gitlab.com/getting-help/).

The [GitLab issue tracker on GitLab.com][gitlab-tracker] is the right place for bugs and feature proposals about Security Products.
Please use the ~"Category:Container Scanning" labels when opening a new issue to ensure it is quickly reviewed by the right people.

**[Search the issue tracker][gitlab-tracker]** for similar entries before
submitting your own, there's a good chance somebody else had the same issue or
feature proposal. Show your support with an award emoji and/or join the
discussion.

Not all issues will be addressed and your issue is more likely to
be addressed if you submit a merge request which partially or fully solves
the issue. If it happens that you know the solution to an existing bug, please first
open the issue in order to keep track of it and then open the relevant merge
request that potentially fixes it.

[gitlab-tracker]: https://gitlab.com/gitlab-org/gitlab/issues

### Merge Requests

When opening a new merge request, please use the description template to provide details about your changes.
[Danger](https://danger.systems/ruby/) will comment on your merge request to provide guidance on what you should do,
and will also recommend a reviewer. Please add this person as a reviewer on your merge request to ensure that
your request is reviewed.

## Contributor Code of conduct

We want to create a welcoming environment for everyone who is interested in contributing.
Visit our [Code of Conduct page](https://about.gitlab.com/community/contribute/code-of-conduct/) 
to read our community pledge and standards.

## Transient dependencies

In order to keep the image small, dependencies that do not remain in the final image must be added, used, and removed in
the same Dockerfile `RUN` command  so that the disk usage isn't committed into a layer.

Some dependencies for this project are stored in the GitLab package registry at 
https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/packages.

The GitLab [package registry documentation](https://docs.gitlab.com/ee/user/packages/package_registry/) explains how to
use the registry to store and retrieve files. Here's an example of how to upload a generic package:

```bash
curl --header "PRIVATE-TOKEN: <YOUR-RW-TOKEN>" \
     --upload-file ./oras \
     "https://gitlab.com/api/v4/projects/24673064/packages/generic/oras/0.12.0/oras"
```
