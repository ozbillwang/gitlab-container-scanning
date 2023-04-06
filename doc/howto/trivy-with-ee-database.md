# Gitlab EE Trivy database build flow
This diagram describes how the EE database is built and includes links to the source code and scheduled pipelines.
<div class="center">

```mermaid
graph TD
   %% Legend for nodes: 
   %% VD: Advisories Data Files compatible for trivy consumption
   %% SP: Scheduled Pipelines
   %% D: Database
   %% A: Action
   %% CS: Container scanning image

   subgraph 1
   %% Nodes
   1_SP[Trivy DB GLAD scheduled pipeline]
   1_VD1[(GLAD Ultimate Edition Advisories)]
   1_VD2[(Trivy Advisories)]
   1_D1[(trivy.db used in EE)]
   1_A1[Transform GLAD to Trivy compatible format]
   1_A2[Fetch all other advisory data sources that Trivy supports]
   1_A3[Remove Open Source GLAD]
   1_A4[Remove alpine and oracle advisories due to licensing restrictions]
   1_A5[Generate trivy.db with advisories]
   
   %% Links
   1_SP-->1_A1-->1_VD1
   1_SP-->1_A2-->1_VD2
   1_VD1-->1_A5-->1_D1
   1_VD2-->1_A3-->1_A4-->1_A5

   %% Clicks
   click 1_SP "https://gitlab.com/gitlab-org/security-products/dependencies/trivy-db-glad/-/pipeline_schedules"
   click 1_A1 "https://gitlab.com/gitlab-org/security-products/dependencies/trivy-db-glad/-/blob/d771d8843ffded3118135b5bd127baf8b7460577/.gitlab-ci.yml#L35-36"
   click 1_A2 "https://gitlab.com/gitlab-org/security-products/dependencies/trivy-db-glad/-/blob/d771d8843ffded3118135b5bd127baf8b7460577/.gitlab-ci.yml#L68"
   click 1_A3 "https://gitlab.com/gitlab-org/security-products/dependencies/trivy-db-glad/-/blob/d771d8843ffded3118135b5bd127baf8b7460577/.gitlab-ci.yml#L76"
   click 1_A4 "https://gitlab.com/gitlab-org/security-products/dependencies/trivy-db-glad/-/blob/d771d8843ffded3118135b5bd127baf8b7460577/.gitlab-ci.yml#L77"
   click 1_A5 "https://gitlab.com/gitlab-org/security-products/dependencies/trivy-db-glad/-/blob/d771d8843ffded3118135b5bd127baf8b7460577/.gitlab-ci.yml?ref_type=heads#L87-89"
   click 1_D1 "https://gitlab.com/gitlab-org/security-products/dependencies/trivy-db-glad/container_registry"
   end

   subgraph 2
   %% Nodes
   2_SP[Alpine Advisories scheduled pipeline]
   2_A1[Generate Alpine advisories in Trivy compatible format]
   2_VD1[(Alpine Advisories)]

   %% Links
   2_SP-->2_A1-->2_VD1-->1_A5
   
   %% Clicks
   click 2_SP "https://gitlab.com/gitlab-org/secure/vulnerability-research/advisories/advgen4cs-workflow"
   end

   subgraph 3
   %% Nodes
   3_SP[Oracle Advisories scheduled pipeline]
   3_VD1[(Oracle Advisories)]
   3_A1[Generate Oracle advisories in Trivy compatible format]

   %% Links
   3_SP-->3_A1-->3_VD1-->1_A5

   %% Clicks
   click 3_SP "https://gitlab.com/gitlab-org/security-products/rhsa2ovaloracle"
   end

   subgraph 4
   %% Nodes
   4_SP[Trigger DB Update scheduled pipeline]
   4_A1[Trigger a new build for each major version of container scanner]
   4_A2[Fetch latest trivy.db to create new image with latest advisories]
   4_CS1([V4.x CS image])
   4_CS2([V5.x CS image])

   %% Links
   1_D1-->4_SP-->4_A1-->4_A2
   4_A2-->4_CS1
   4_A2-->4_CS2

   %% Clicks
   click 4_SP "https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/pipeline_schedules"
   click 4_A1 "https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/blob/b9f2d321499ba2185edb1f3768cef73b6b4a79cd/Rakefile#L175-191"
   click 4_A2 "https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/blob/30ef57d7ad7e6f4fca7c63f9eb23ef490efe4837/script/setup.sh#L28-31"
   end

   subgraph 5
   %% Nodes
   5_SP[Check if vulnerability DB is outdated scheduled pipeline]
   5_A1[Check if latest CS image contains outdated DB]

   %% Links
   5_SP-->5_A1
   4_CS1-->5_A1
   4_CS2-->5_A1

   %% Clicks
   click 5_SP "https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/pipeline_schedules"
   click 5_A1 "https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/blob/b9f2d321499ba2185edb1f3768cef73b6b4a79cd/.gitlab/ci/maintenance.yml#L53-72"
   end

   %% Define class for action nodes to enable adding of URLs
   classDef actionNode fill:none,stroke:none;
   classDef withURL color:#1068bf,text-decoration:underline;
   class 1_A1,1_A2,1_A3,1_A4,1_A5,2_A1,3_A1,4_A1,4_A2,5_A1 actionNode;
   class 1_SP,2_SP,3_SP,4_SP,5_SP,D1,1_A1,1_A2,1_A3,1_A4,1_A5,4_A1,4_A2,5_A1 withURL;
```
</div>

# How to run Trivy locally with the EE database

The Trivy databse is a [bbolt](https://github.com/etcd-io/bbolt) database file
which is stored on the file system inside `$CACHE_DIR/trivy/db/`. `$CACHE_DIR`
is the output of [`os.UserCacheDir`](https://pkg.go.dev/os#UserCacheDir),
which varies depending on your operating system. We host the EE database
as a blob inside the GitLab container registry. To use it, you will need to download it,
place it inside the cache directory, then run Trivy with the `--skip-db-update` flag.
Continue reading for more details on how to do this.

## Prerequisites

1. [Install Trivy](https://aquasecurity.github.io/trivy/latest/getting-started/installation/)
1. [Install ORAS](https://oras.land/cli/)

## Installing the EE Database

1. Determine your cache directory by referencing [`os.UserCacheDir`](https://pkg.go.dev/os#UserCacheDir).
   On MacOS it is `~/Library/Caches/`. On Linux it is `~/.cache` (most of the time).

   ```shell
   export CACHE_DIR=~/Library/Caches
   ```

1. Run `trivy i --reset` to remove any existing databases. This will ensure you are using the correct one.
1. Use ORAS to download the EE database and place it inside your cache.

   ```shell
   mkdir -p "${CACHE_DIR}/trivy/db"
   oras pull registry.gitlab.com/gitlab-org/security-products/dependencies/trivy-db-glad:2 -a && \
     tar -zxvf db.tar.gz -C "${CACHE_DIR}/trivy/db" && \
     rm db.tar.gz
   ```

1. Run trivy with `--skip-db-update` to avoid replacing the EE database with the default Trivy DB:

    ```shell
    $ trivy i --skip-db-update amazoncorretto:8
    2022-05-19T06:38:56.609-0500	INFO	Detected OS: amazon
    2022-05-19T06:38:56.609-0500	INFO	Detecting Amazon Linux vulnerabilities...
    2022-05-19T06:38:56.612-0500	INFO	Number of language-specific files: 0

    amazoncorretto:8 (amazon 2 (Karoo))
    ===================================
    Total: 8 (UNKNOWN: 0, LOW: 0, MEDIUM: 8, HIGH: 0, CRITICAL: 0)

    +---------+------------------+----------+--------------------+--------------------+---------------------------------------+
    | LIBRARY | VULNERABILITY ID | SEVERITY | INSTALLED VERSION  |   FIXED VERSION    |                 TITLE                 |
    +---------+------------------+----------+--------------------+--------------------+---------------------------------------+
    | curl    | CVE-2022-22576   | MEDIUM   | 7.79.1-1.amzn2.0.1 | 7.79.1-2.amzn2.0.1 | curl: OAUTH2 bearer bypass            |
    |         |                  |          |                    |                    | in connection re-use                  |
    |         |                  |          |                    |                    | -->avd.aquasec.com/nvd/cve-2022-22576 |
    +         +------------------+          +                    +                    +---------------------------------------+
    |         | CVE-2022-27774   |          |                    |                    | curl: credential leak on redirect     |
    |         |                  |          |                    |                    | -->avd.aquasec.com/nvd/cve-2022-27774 |
    +         +------------------+          +                    +                    +---------------------------------------+
    |         | CVE-2022-27775   |          |                    |                    | curl: bad local IPv6 connection reuse |
    |         |                  |          |                    |                    | -->avd.aquasec.com/nvd/cve-2022-27775 |
    +         +------------------+          +                    +                    +---------------------------------------+
    |         | CVE-2022-27776   |          |                    |                    | curl: auth/cookie leak on redirect    |
    |         |                  |          |                    |                    | -->avd.aquasec.com/nvd/cve-2022-27776 |
    +---------+------------------+          +                    +                    +---------------------------------------+
    | libcurl | CVE-2022-22576   |          |                    |                    | curl: OAUTH2 bearer bypass            |
    |         |                  |          |                    |                    | in connection re-use                  |
    |         |                  |          |                    |                    | -->avd.aquasec.com/nvd/cve-2022-22576 |
    +         +------------------+          +                    +                    +---------------------------------------+
    |         | CVE-2022-27774   |          |                    |                    | curl: credential leak on redirect     |
    |         |                  |          |                    |                    | -->avd.aquasec.com/nvd/cve-2022-27774 |
    +         +------------------+          +                    +                    +---------------------------------------+
    |         | CVE-2022-27775   |          |                    |                    | curl: bad local IPv6 connection reuse |
    |         |                  |          |                    |                    | -->avd.aquasec.com/nvd/cve-2022-27775 |
    +         +------------------+          +                    +                    +---------------------------------------+
    |         | CVE-2022-27776   |          |                    |                    | curl: auth/cookie leak on redirect    |
    |         |                  |          |                    |                    | -->avd.aquasec.com/nvd/cve-2022-27776 |
    +---------+------------------+----------+--------------------+--------------------+---------------------------------------+
    ```
