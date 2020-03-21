# Background information

## Why [GitHub][github]?

* It's free for open-source projects
* It's ubiquitous
* I really like [GitLab][gitlab], but AppVeyor has in-built support for [GitHub Releases][github-releases] which clinched it for me

## Why [AppVeyor][appveyor]?

* It's free for open-source projects
* It supports Windows, Linux and macOS
* It seems solid and reliable
* It has built-in GitHub Releases support

## Tools available in AppVeyor CI/CD environment

It turns out that PowerShell is the most generally available and consistent scripting environment available in AppVeyor in all standard build images (Windows, Linux and macOS). Therefore, rust-appveyor-build-pack is authored exclusively in PowerShell. It depends on the following tools:

* [PowerShell Core][powershell-core]
* [Git][git]
* [7-Zip][7zip] on Windows and [Info-ZIP][info-zip] on Linux and macOS

With these tools installed locally, you can fairly faithfully simulate an AppVeyor CI/CD environment for development and testing.

## AppVeyor environment

After much probing of AppVeyor, I figured out which PowerShell variables and environment variables are needed to implement a sensible build and publishing system. For the historical record, I have summarized my findings below.

### Common variables

These values are consistently defined across all build images (Windows, Linux and macOS):

* `$thisDir`, `$currentDir` and `APPVEYOR_BUILD_FOLDER` \
  All set to Git repo root directory
* `APPVEYOR_BUILD_ID` \
  The build ID (same for all jobs)
* `APPVEYOR_BUILD_NUMBER` \
  The build number (same for all jobs)
* `APPVEYOR_BUILD_VERSION` \
  The build version (same for all jobs)
* `APPVEYOR_JOB_ID` \
  The job ID which is unique for each job
* `APPVEYOR_PROJECT_SLUG` \
  The project name's slug&mdash;roughly the same as the GitHub project name
* `APPVEYOR_REPO_COMMIT` \
  The commit hash: the Git repo will always be checked out in detached-`HEAD` state checked out at this commit
* `APPVEYOR_REPO_NAME` \
  The name of the project&mdash;typically the owner and the GitHub project name

### Windows-specific values

* `$IsWindows` is `True`
* `APPVEYOR` is `True`
* `APPVEYOR_BUILD_WORKER_IMAGE` is `Visual Studio 2015`
* `CI` is `True`

### Linux-specific values

* `$IsLinux` is `True`
* `APPVEYOR` is `True`
* `APPVEYOR_BUILD_WORKER_IMAGE` is `Ubuntu`
* `CI` is `true`

### macOS-specific values

* `$IsMacOS` is `True`
* `APPVEYOR` is `true`
* `APPVEYOR_BUILD_WORKER_IMAGE` is `macOS`
* `CI` is `true`

### Tag builds

Triggered when _tags_ are pushed to GitHub

* `APPVEYOR_REPO_BRANCH` is the tag name
* `APPVEYOR_REPO_TAG` is `true`
* `APPVEYOR_REPO_TAG_NAME` is the tag name

### Branch builds

Triggered when _branches_ are pushed to GitHub

* `APPVEYOR_REPO_BRANCH` is the branch name
* `APPVEYOR_REPO_TAG` is `false`

### Notes

Note that pushing a tag will often trigger _both_ a tag build _and_ branch build if the commits are new to GitHub and also on a branch (which they will be usually). This will be the case if you use the [exmaple `appveyor.yml` configuration][appveyor-yml-example].

[7zip]: https://www.7-zip.org/
[appveyor]: https://appveyor.com/
[appveyor-yml-example]: appveyor.yml.example
[git]: https://git-scm.com/
[github]: https://github.com/
[github-releases]: https://help.github.com/en/github/administering-a-repository/managing-releases-in-a-repository
[gitlab]: https://gitlab.com/
[info-zip]: http://infozip.sourceforge.net/
[powershell-core]: https://github.com/PowerShell/PowerShell
