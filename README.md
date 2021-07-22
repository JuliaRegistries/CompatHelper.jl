# CompatHelper.jl

`CompatHelper.jl` is a Julia package which keeps your `Project.toml` `[compat]` entries up to date.

| Category          | Status                                                                                  |
| ----------------- | --------------------------------------------------------------------------------------- |
| Unit Tests        | [![Continuous Integration (Unit Tests)][ci-unit-img]][ci-unit-url]                      |
| Integration Tests | [![Continuous Integration (Integration Tests)][ci-integration-img]][ci-integration-url] |
| Documentation     | [![Documentation][docs-img]][docs-url]                                                  |
| Code Coverage     | [![Code Coverage][codecov-img]][codecov-url]                                            |
| Style Guide       | [![Style Guide][bluestyle-img]][bluestyle-url]                                          |

[docs-img]: https://img.shields.io/badge/-documentation-blue.svg "Documentation"
[docs-url]: https://JuliaRegistries.github.io/CompatHelper.jl/dev/
[ci-unit-img]: https://github.com/JuliaRegistries/CompatHelper.jl/actions/workflows/ci_unit.yml/badge.svg?branch=master "Continuous Integration (Unit Tests)"
[ci-unit-url]: https://github.com/JuliaRegistries/CompatHelper.jl/actions/workflows/ci_unit.yml
[ci-integration-img]: https://github.com/JuliaRegistries/CompatHelper.jl/actions/workflows/ci_integration.yml/badge.svg?branch=master "Continuous Integration (Integration Tests)"
[ci-integration-url]: https://github.com/JuliaRegistries/CompatHelper.jl/actions/workflows/ci_integration.yml
[codecov-img]: https://codecov.io/gh/JuliaRegistries/CompatHelper.jl/branch/master/graph/badge.svg "Code Coverage"
[codecov-url]: https://codecov.io/gh/JuliaRegistries/CompatHelper.jl/branch/master
[bluestyle-img]: https://img.shields.io/badge/code%20style-blue-4495d1.svg "Blue Style"
[bluestyle-url]: https://github.com/invenia/BlueStyle

## Setup
### GitHub
TODO

### GitLab
TODO
### Environment Variables

| Name | Description |
| ---- | ----------- |
| CI_PROJECT_PATH | Name on GitLab of the `organization/repo`, provided by default on GitLab |
| GIT_COMMITTER_NAME | Name to associate commits with |
| GIT_COMMITTER_EMAIL | Email to associate commits with |
| GITHUB_ACTOR | Users on GitHub to CC on pull requests |
| GITHUB_REPOSITORY | Name on GitHub of the `organization/repo`, provided by default on GitHub |
| GITHUB_TOKEN | GitHub Access Token, provided by default by GitHub Actions |
| GITLAB_TOKEN | GitLab Access Token, provided by default by GitLab CI |
| GITLAB_USER_LOGIN | Users on GitLab to CC on pull requests |
