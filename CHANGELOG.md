## 4.5.14 (2022-01-26)

### changed (1 change)

- [Update grype to version 0.32.0](gitlab-org/security-products/analyzers/container-scanning@950c6914ebd2ad11a1b30913e3d2bbf398350048) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2649))

## 4.5.13 (2022-01-18)

### changed (2 changes)

- [Update trivy to version 0.22.0](gitlab-org/security-products/analyzers/container-scanning@1a215f4a5d602d4507ef312ddd0d6e4ba6f54958) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2647))
- [Update grype to version 0.31.1](gitlab-org/security-products/analyzers/container-scanning@fc76e1e1cf5543ffe9df8329afa3a016a46c2d50) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2646))

## 4.5.12 (2022-01-17)

### fixed (3 changes)

- [Return empty dependency report when no dependencies were found](gitlab-org/security-products/analyzers/container-scanning@c563753293d30f7b79e29c73e00a284bf566d103) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2644))
- [Remove unnecessary dependencies](gitlab-org/security-products/analyzers/container-scanning@0bf4c7bed2845076a4a52529019d042638c43c69) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2639))
- [Remove unnecessary dependencies](gitlab-org/security-products/analyzers/container-scanning@eeca1250e59ac84d642459fdec7504101a3ff3d3) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2640))

## 4.5.10 (2021-12-21)

### fixed (1 change)

- [Fix schema validation mis-alignment with rails](gitlab-org/security-products/analyzers/container-scanning@36f46d1c16af505e0dc808b27da81722c32cc9eb) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2635))

## 4.5.9 (2021-12-17)

### fixed (1 change)

- [Fix value for vulnerability[].location.image for trivy language scan](gitlab-org/security-products/analyzers/container-scanning@5930e9eb5b59699864ce9bb2ca1545d3966bee63) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2633))

## 4.5.8 (2021-12-15)

### changed (4 changes)

- [Update grype to version 0.27.2](gitlab-org/security-products/analyzers/container-scanning@e29f457c2c5e57ab42cde60de2af5f283ebc3b1d) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2632))
- [Rename CS_DISABLE_DEPENDENCY_SCAN to CS_DISABLE_DEPENDENCY_LIST](gitlab-org/security-products/analyzers/container-scanning@05b74a47a9b44bb97a7a110f15ee9443ac856bbf) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2630))
- [Enable generating dependency-scanning report by default](gitlab-org/security-products/analyzers/container-scanning@77df348fa6919aa2135d9e00bc3a48a63917c9c8) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2627))
- [Update grype to version 0.27.0](gitlab-org/security-products/analyzers/container-scanning@b3eeac94ae1c9ba5c30197cb0550963e31196310) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2622))

### added (3 changes)

- [Add fetching vulnerabilities for language packages in container](gitlab-org/security-products/analyzers/container-scanning@dced5a812ab52281ac3f701a52947cb765a29d74) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2629))
- [Enable fetching language-specific vulnerabilities for grype](gitlab-org/security-products/analyzers/container-scanning@589488c37d0ef797f974ed47a6ab3c9d6b89257d) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2631))
- [Add support for language-specific dependency list](gitlab-org/security-products/analyzers/container-scanning@44a7a7ff58466445b3365fae822b780718584b7b) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2628))

## 4.5.5 (2021-12-09)

### added (1 change)

- [Return empty Dependency Scanning report when disabled](gitlab-org/security-products/analyzers/container-scanning@9384a1d87bb566a4d591a80a5f638703eaf562bd) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2619))

## 4.5.4 (2021-12-09)

### added (1 change)

- [Return empty Dependency Scanning report when disabled](gitlab-org/security-products/analyzers/container-scanning@9384a1d87bb566a4d591a80a5f638703eaf562bd) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2619))

### changed (2 changes)

- [Update grype to version 0.26.1](gitlab-org/security-products/analyzers/container-scanning@be4cc2c71dc48d9ab61c7309a2a383bc0c7b5514) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2621))
- [Update trivy to version 0.21.2](gitlab-org/security-products/analyzers/container-scanning@d4a16029648ad5e103a78a22a78f32d12790d37b) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2620))

## 4.5.2 (2021-12-05)

### changed (1 change)

- [Remove default value for default_branch_image](gitlab-org/security-products/analyzers/container-scanning@de352f0c48c4b0b26c6c00f7a9f8007ce4e8dbb6) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2615))

## 4.5.1 (2021-11-26)

No changes.

## 4.4.2 (2021-11-15)

### changed (2 changes)

- [Update trivy to version 0.21.0](gitlab-org/security-products/analyzers/container-scanning@f1ca6990909d56cf2382f194632c8d3ef650c026) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2614))
- [Update grype to version 0.24.1](gitlab-org/security-products/analyzers/container-scanning@05397b325a37306a9daf5328469d9d946b76af62) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2612))

## 4.4.1 (2021-11-12)

### fixed (1 change)

- [Decouple default_branch_image from GitLab](gitlab-org/security-products/analyzers/container-scanning@fcb281098625ebc84e6cf68bd51a588b5265f012) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2611))

### changed (1 change)

- [Upgrade security report schemas to v14.0.6](gitlab-org/security-products/analyzers/container-scanning@ba8ecbcdb49310e2fdade3ff3244ec8488592f3d) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2610))

## 4.4.0 (2021-11-09)

### added (1 change)

- [Add default_branch_image to security report](gitlab-org/security-products/analyzers/container-scanning@401e0ab43f8ab02f9d308c1bf01b459c8346ea04) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2602))

### changed (2 changes)

- [Update grype to version 0.24.0](gitlab-org/security-products/analyzers/container-scanning@86ffce8b8faa34830cfaa0d4c6fed2d492e6c013) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2605))
- [Update trivy to version 0.20.2](gitlab-org/security-products/analyzers/container-scanning@cf39fd61a70851dcd0e819e3d58096d3c9b61a5e) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2604))

### other (1 change)

- [Fix unit tests that edit local Dockerfile](gitlab-org/security-products/analyzers/container-scanning@a8bb5296641ec8915bc711f39e338629d6bfe8c5) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2601))

## 4.3.18 (2021-10-25)

### changed (2 changes)

- [Update grype to version 0.23.0](gitlab-org/security-products/analyzers/container-scanning@97986be5f92919e91aeeed262b24fc7ccebbd9c0) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2598))
- [Update trivy to version 0.20.1](gitlab-org/security-products/analyzers/container-scanning@c08423fd6b2a5c8d4f1802852dabc013c234a6b6) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2597))

## 4.3.17 (2021-09-29)

### changed (1 change)

- [Update grype to version 0.21.0](gitlab-org/security-products/analyzers/container-scanning@35b1fa217b7def5cbb0acd0119f0f30a44f62869) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2594))

## 4.3.16 (2021-09-27)

No changes.

## 4.3.15 (2021-09-22)

### fixed (2 changes)

- [Show Grype under GitLab in the security report Tool filter](gitlab-org/security-products/analyzers/container-scanning@bc329b235b35dce840fa4199bc92ce4fd080618d) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2591))
- [Revert "Fix Trivy vendor name in scan report"](gitlab-org/security-products/analyzers/container-scanning@fd309d1987fb5e812dfe3d587f077b46cbc21c4d) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2591))

## 4.3.14 (2021-09-21)

### fixed (1 change)

- [Fix Trivy vendor name in scan report](gitlab-org/security-products/analyzers/container-scanning@35e9ddf33d34b88180ee07866b9776d239772e87) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2588))

### changed (1 change)

- [Update grype to version 0.19.0](gitlab-org/security-products/analyzers/container-scanning@07a2cd00a716168fbab418b78eb6d2e65700d980) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2589))

## 4.3.13 (2021-09-15)

### changed (1 change)

- [Update grype to version 0.18.0](gitlab-org/security-products/analyzers/container-scanning@87165db10401b27fa94e709ca2d377356400c4d3) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2584))

## 4.3.12 (2021-09-14)

### changed (1 change)

- [Include analyzer metadata in the security report](gitlab-org/security-products/analyzers/container-scanning@d9abc6d95b5299c63e57be17053373a1c1292f81) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2583))

## 4.3.11 (2021-09-06)

### fixed (1 change)

- [Improve error message for inaccessible image](gitlab-org/security-products/analyzers/container-scanning@ca05b93ec84c6aed035e722f13788121aa151aea) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2581))

## 4.3.10 (2021-09-01)

### added (1 change)

- [Add Grype support for CS_REGISTRY_INSECURE](gitlab-org/security-products/analyzers/container-scanning@aeb2095458d57bd797c054689ecac2c855105674) by @kzantow ([merge request](gitlab-org/security-products/analyzers/container-scanning!2580))

### changed (1 change)

- [Update Grype to 0.16.0](gitlab-org/security-products/analyzers/container-scanning@e3c575cc241a261e573c0f9f4bc6d6891e7348cd) by @kzantow ([merge request](gitlab-org/security-products/analyzers/container-scanning!2579))

### fixed (1 change)

- [Improve error message when image not found and credentials are invalid](gitlab-org/security-products/analyzers/container-scanning@477e41aff02c13764cffe53334b65526d6bccb33) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2573))

## 4.3.9 (2021-08-19)

### fixed (1 change)

- [Show path to docker file in remediation error](gitlab-org/security-products/analyzers/container-scanning@2630f5e304ff2efe16d9f2d2907963712b5629a8) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2577))

## 4.3.8 (2021-08-19)

### fixed (5 changes)

- [Fix Photon OS remediation](gitlab-org/security-products/analyzers/container-scanning@2bd979e29fceb9c56b8eb18d5689a282a2e18757) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2571))
- [Fix OpenSUSE, OpenSUSE/Leap remediation](gitlab-org/security-products/analyzers/container-scanning@1f78b24904014b8ec6833b80928fbf168bd26640) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2571))
- [Fix remediation for Amazon Linux](gitlab-org/security-products/analyzers/container-scanning@ddaac62f0f47b7833fc3cfc5e86acbac01cec2e4) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2571))
- [Fix remediation for Red Hat and Red Hat UBI](gitlab-org/security-products/analyzers/container-scanning@265c03daa9b78e4e84f5aec7684e2444da6fcd49) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2571))
- [Fix remediation for Oracle Linux](gitlab-org/security-products/analyzers/container-scanning@0abf66d1c6fa7270eaa5833a62d7fe728ea50edd) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2571))

### changed (1 change)

- [Add details to remediation error message](gitlab-org/security-products/analyzers/container-scanning@38d1b0a322df03ff7b6ffaf178fc009f06194f54) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2570))

## 4.3.7 (2021-08-04)

### changed (1 change)

- [Update log messages for allow list usage](gitlab-org/security-products/analyzers/container-scanning@da466176dc76426cf36e17b70c6c480d3175f295) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2569))

### security (1 change)

- [Upgrade `addressable` gem](gitlab-org/security-products/analyzers/container-scanning@a17b8b8c28c2a7c0c4b2d16d06262da766cf888a) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2565))

## 4.3.6 (2021-07-29)

### changed (2 changes)

- [Update Grype to 0.15.0](gitlab-org/security-products/analyzers/container-scanning@366c6f670c8e38e58057a3903eff5a2eea939833) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2555))
- [Fix anonymous access to public docker registries](gitlab-org/security-products/analyzers/container-scanning@190816994a18bc81daae6a4eb853e237ce9e4c9a) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2560))

## 4.3.5 (2021-07-28)

### fixed (1 change)

- [Fix crash when performing auto-remediation for an unknown OS](gitlab-org/security-products/analyzers/container-scanning@fe5fe7bfce4069c5f9398068934e3aa4e070a87e) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2550))

## 4.3.4 (2021-07-14)

### other (5 changes)

- [Update trivy version in template](gitlab-org/security-products/analyzers/container-scanning@ea73f6f6561dd19106f24818e989eb057d0341ca) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2537))
- [Use permalink for Trivy template reference](gitlab-org/security-products/analyzers/container-scanning@b98f16aaa028ed0a7b5c7904ba25452a70d2968c) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2532))
- [Upload test reports](gitlab-org/security-products/analyzers/container-scanning@82c3397a4d85e6278376dc50fbd202ff3b8a82e5) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2529))
- [Follow existing pattern for setting Grype version](gitlab-org/security-products/analyzers/container-scanning@e6b6ab19427438785a1b2ab9e686f4522a3689b3) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2530))
- [Enforce adding changelog trailer](gitlab-org/security-products/analyzers/container-scanning@3fa48de1dd3d77027861e6d10b1cfda6feca02d5) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2526))

## 4.3.3 (2021-07-06)

No changes.

## 4.3.2 (2021-07-05)

No changes.

## 4.3.1 (2021-06-16)

No changes.

## 4.3.0 (2021-06-10)

### Added (1 change)

- [Updating the version with the latest changes (including Grype)](gitlab-org/security-products/analyzers/container-scanning@64b3271322a5d2f0f2531af07480d52dd4f57754) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2513))

### fixed (2 changes)

- [Remove redundant invocation of trivy version command](gitlab-org/security-products/analyzers/container-scanning@fe8d3f79b23509d7c84b90e83ff7c8c6cca01113) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2512))
- [Fix image name and operating_system name edge case error](gitlab-org/security-products/analyzers/container-scanning@eacc9481e422a911bde36271bc564a7453157ad6) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2510))

### added (1 change)

- [This commit adds grype to the supported scanners.](gitlab-org/security-products/analyzers/container-scanning@1d517c2a9dbdf5acefc3c391da60377421860e80) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2480))

## 4.2.2 (2021-06-10)

Yanked.

## 4.2.1 (2021-06-04)

No changes.

## 4.2.0 (2021-06-03)

### added (1 change)

- [Add support for CS_DOCKER_INSECURE and CS_REGISTRY_INSECURE](gitlab-org/security-products/analyzers/container-scanning@1f74da406afd4278e6ca02e5dba322003fafbf4b) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2497))

## 4.1.10 (2021-05-30)

### fixed (1 change)

- [Fix daily update for `latest` tag](gitlab-org/security-products/analyzers/container-scanning@548be2311c59d507374ce33cd8d9f3ab71ee14a3) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2487))

### Added (1 change)

- [Set `TRIVY_DEBUG` correctly based on `SECURE_LOG_LEVEL` env variable](gitlab-org/security-products/analyzers/container-scanning@d747a49f0b8cbb21c6f44579b31c49e7d4817203) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2471))

## 4.1.9 (2021-05-24)

### changed (2 changes)

- [Publish images to new production registry](gitlab-org/security-products/analyzers/container-scanning@132787fa7f3b93052f15272e1e08032019b9b9d6) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2482))
- [Set development & runtime Ruby versions as 2.7.3](gitlab-org/security-products/analyzers/container-scanning@fe27e4c242d50b4a8627776f74520281acc6a0b6) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2469))

### added (1 change)

- [Show version information in CI logs](gitlab-org/security-products/analyzers/container-scanning@f02e80870ada160cc64bb3589597325a40dd2ae3) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2476))

## 4.1.8 (2021-05-21)

### fixed (1 change)

- [Add ruby dependency to tag version job](gitlab-org/security-products/analyzers/container-scanning@71d1f6ed19594c4dbd570845de9069f910f7c8cc) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2475))

### changed (2 changes)

- [Upgrade trivy to 0.18.2](gitlab-org/security-products/analyzers/container-scanning@1dbc0a51341e0966bb1a085a232bdb3b2cb60fc2) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2474))
- [Update Trivy version 2021-05-13](gitlab-org/security-products/analyzers/container-scanning@d025a14932868391718474c162570356e5c91b94) ([merge request](gitlab-org/security-products/analyzers/container-scanning!40))

### added (1 change)

- [Add quite variable to reduce output](gitlab-org/security-products/analyzers/container-scanning@43cbf0944c69e21176b17667d7f96cd995f862c8) ([merge request](gitlab-org/security-products/analyzers/container-scanning!50))

## 4.1.7 (2021-05-13)

No changes.

## 4.1.6 (2021-05-11)

### added (2 changes)

- [Update rubocop rules](gitlab-org/security-products/analyzers/container-scanning@3604b92decec94da9db20665b6a494704c626f33) ([merge request](gitlab-org/security-products/analyzers/container-scanning!26))
- [Add maintenance job to keep vulnerability db updated](gitlab-org/security-products/analyzers/container-scanning@13176a521b7276878fadb415965c05a4f7680c9f) ([merge request](gitlab-org/security-products/analyzers/container-scanning!20))

### Added (2 changes)

- [Add job for checking commit message format](gitlab-org/security-products/analyzers/container-scanning@f7e86499f08493dbd5d8979458190cd4a605c940) ([merge request](gitlab-org/security-products/analyzers/container-scanning!23))
- [Use gitlab changelog generator](gitlab-org/security-products/analyzers/container-scanning@a160206edd85a3fad1460cdffc1e8e1fdcda2ecc) ([merge request](gitlab-org/security-products/analyzers/container-scanning!22))
