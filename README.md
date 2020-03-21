# rust-appveyor-build-pack

[![AppVeyor build status](https://ci.appveyor.com/api/projects/status/w2nmlj9ljfkp10kh/branch/master?svg=true)][appveyor-master]

_Build and test Rust-based projects in AppVeyor and publish artifacts to GitHub_

* [Official home page][home]

## Recommended development model

* New features and bug fixes are developed on feature branches
* Feature branches are eventually rebased on top of master and merged to master
* Official releases commits marked with _annotated_ tags

## Features

* Pushes of branches, tags or commits trigger build and test in AppVeyor
* Pushes of "release" tags in format `vMAJOR.MINOR.PATCH` trigger build and test in AppVeyor and deployment of artifacts to GitHub Releases page

## Licence

* [MIT License][licence]

[appveyor-master]: https://ci.appveyor.com/project/rcook/rust-appveyor-build-pack/branch/master
[home]: https://github.com/rcook/rust-appveyor-build-pack
[licence]: LICENSE
