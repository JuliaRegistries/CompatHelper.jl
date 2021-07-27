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
Create a file at `.github/workflows/CompatHelper.yml` with the following contents,

```@eval
 import CompatHelper
 import Markdown

 const root_directory = dirname(dirname(pathof(CompatHelper)))
 const workflow_dir = joinpath(root_directory, ".github", "workflows")
 const workflow_filename = joinpath(workflow_dir, "CompatHelper.yml")
 const workflow_filecontents = read(workflow_filename, String)
 const str = string("```yaml\n", strip(workflow_filecontents), "\n```")
 const md = Markdown.parse(str)
 return md
 ```

If you need to use any special arguments for the `main` function, you can modify this file to add them.

### GitLab
For GitLab you will want to add CompatHelper as a job in your `.gitlab-ci.yml` file such as:

```yaml
CompatHelper:
  image: julia:1.6 # Set to the Julia version you want to use
  stage: compat # You can place this in any stage that makes sense for your setup
  before_script:
    - apt-get update -qq && apt-get install -y git
    - |
      julia --color=yes -e "
        import Pkg
        name = "CompatHelper"
        uuid = "aa819f21-2bde-4658-8897-bab36330d9b7"
        version = "3"
        Pkg.add(; name, uuid, version)"
  script:
    - |
      julia --color=yes -e "
        import CompatHelper
        CompatHelper.main()"
```

Similarly to the GitHub setup, you can modify the `main` call here if you need to change any of the default arguments.
You must also remember to add the `GITLAB_TOKEN` and `COMPATHELPER_PRIV` CI secrets to the project so that CompatHelper can find them.


### Environment Variables

#### GitHub & GitLab
| Name | Description |
| ---- | ----------- |
| GIT_COMMITTER_NAME | Name to associate commits with |
| GIT_COMMITTER_EMAIL | Email to associate commits with |
| COMPATHELPER_PRIV | Plain Text or Base64 Encoded SSH Public Key for git pushes and API calls |

#### GitHub
| Name | Description |
| ---- | ----------- |
| GITHUB_TOKEN | GitHub Access Token, user for GitHub API Requests |
| GITHUB_REPOSITORY | Name on GitHub of the `organization/repo`, provided by default on GitHub |
| GITHUB_ACTOR | GitHub Username that triggered the Action, provided by default by GitHub Actions. This is used to CC the user on the pull request if enabled |

#### GitLab
| Name | Description |
| ---- | ----------- |
| GITLAB_TOKEN | GitLab Access Token, used for GitLab API Requests |
| CI_PROJECT_PATH | Name on GitLab of the `organization/repo`, provided by default on GitLab |
| GITLAB_USER_LOGIN | GitLab Username that triggered the Pipeline, provided by defalt by GitLab CI. This is used to CC the user on pull request if enabled |
