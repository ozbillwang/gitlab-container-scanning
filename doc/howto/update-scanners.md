# How scanners are updated monthly
The pipeline `Check if scanners are outdated` [is scheduled to run every 11th of the month](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/pipeline_schedules). It will generate MRs for new versions of Trivy or Grype. Once the MR is generated, a team member should follow the checklist in the MR to release the updated scanner.

# Scheduled pipeline configuration

The `Check if scanners are outdated` scheduled pipeline is executed to run automatic scanner updates. To run correctly, it needs the following CI/CD variables:

* `TRIGGER_SCANNER_UPDATE` - **true/false** - if set to **true**, it triggers scanner update during pipeline execution.
* `CS_REVIEWERS_GROUP_ID` - **integer** - a reviewer for the created MR will be picked from the group with this ID.

# Update scanner manually

To update a scanner to the latest version, run `bundle exec rake update_<scanner_name>` to create a branch with the updated
version, then push your changes and create a new MR. Example:
```bash
$ bundle exec rake update_trivy
Version has changed from 0.18.1 to 0.19.1
creating update-trivy-to-0.19.1-2021-07-19 branch
$ git push
```