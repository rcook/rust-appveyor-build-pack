# Prerequisites

* [PowerShell Core][powershell-core]

# Build with rust-appveyor-build-pack

```bash
cd /path/to/sources
git clone git@github.com/rcook/rust-appveyor-build-pack.git
git clone git@github.com/user/project.git
cd project
pwsh ../rust-appveyor-build-pack/Run-Build.ps1 -Refresh
```

[powershell-core]: https://github.com/PowerShell/PowerShell
