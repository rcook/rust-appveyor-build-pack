# rust-appveyor-build-pack

[![AppVeyor status for project](https://ci.appveyor.com/api/projects/status/w2nmlj9ljfkp10kh?svg=true)][status-project]
[![AppVeyor status for master branch](https://ci.appveyor.com/api/projects/status/w2nmlj9ljfkp10kh/branch/master?svg=true)][status-master]

_Build and test Rust-based projects in AppVeyor and publish artifacts to GitHub_

* [Official home page][home]
* [Latest release][latest]

## Overview

I have decided to learn [Rust][rust] properly since the language and [Cargo] tooling have many properties that make them ideal for developing and distributing self-contained (or minimal-dependency) cross-platform tools. In order to share my programs with the world, I needed a way to automatically build and publish them for the three most common platforms (Windows, Linux and macOS). This is the resulting build and deployment system that uses [GitHub][github] to host the source code and [AppVeyor][appveyor] to automatically build, test and publish the binaries.

More technical background can be found [here][background].

## Features

* Pushes of branches, tags or commits trigger build and test in AppVeyor
* Pushes of "release" tags in format `vMAJOR.MINOR.PATCH` trigger build and test in AppVeyor and deployment of artifacts to GitHub Releases page

## Recommended development model

* New features and bug fixes are developed on feature branches
* Feature branches are eventually rebased on top of master and merged to master
* Official releases commits marked with _annotated_ tags

## How to use

Add the following lines to your [`appveyor.yml`][appveyor-yml]:

```yaml
install:
  - ps: Invoke-WebRequest -Uri https://github.com/rcook/rust-appveyor-build-pack/releases/latest/download/rust-appveyor-build-pack.ps1 -OutFile rust-appveyor-build-pack.ps1
  - ps: .\rust-appveyor-build-pack.ps1
```

## Additional resources

* [Example `appveyor.yml`][appveyor-yml-example] \
  You can drop this into the root of your GitHub project to get started.
* [Richard's Workspace Tool][rws] \
  A real project that uses this build pack.
* [ciprobe][ciprobe] \
  A GitHub template repository you can clone to get started.

## Licence

* [MIT License][licence]

[appveyor]: https://appveyor.com/
[appveyor-yml]: https://www.appveyor.com/docs/appveyor-yml/
[appveyor-yml-example]: appveyor.yml.example
[background]: BACKGROUND.md
[cargo]: https://doc.rust-lang.org/cargo/
[ciprobe]: https://github.com/rcook/ciprobe
[github]: https://github.com/
[home]: https://github.com/rcook/rust-appveyor-build-pack
[latest]: https://github.com/rcook/rust-appveyor-build-pack/releases/latest
[licence]: LICENSE
[rust]: https://www.rust-lang.org/
[rws]: https://github.com/rcook/rws
[status-project]: https://ci.appveyor.com/project/rcook/rust-appveyor-build-pack
[status-master]: https://ci.appveyor.com/project/rcook/rust-appveyor-build-pack/branch/master
