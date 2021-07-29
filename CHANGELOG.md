## 4.3.6 (2021-07-29)

### changed (1 change)

- [Update Grype to 0.15.0](gitlab-org/security-products/analyzers/container-scanning@366c6f670c8e38e58057a3903eff5a2eea939833) ([merge request](gitlab-org/security-products/analyzers/container-scanning!2555))

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
