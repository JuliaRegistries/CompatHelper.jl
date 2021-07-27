```@meta
CurrentModule = CompatHelper
```

# Self-Hosting and Other Environments

It is possible to run CompatHelper on custom infrastructure.
This includes GitHub Enterprise, public GitLab, or even private GitLab.
To use any of these you need to just create and pass along the CI Configuration.
The example below would be for a private GitLab server:

```julia
using CompatHelper

ENV["GITLAB_TOKEN"] = "GitLab Personal Access Token"
ENV["CI_PROJECT_PATH"] = "GitLab Repo"
ENV["GITLAB_CI"] = "true"

config = CompatHelper.GitLabCI(;
    username="GitLab Username",
    email="GitLab Email",
    api_hostname="https://gitlab.company.com/api/v4",
    clone_hostname="gitlab.company.com"
)

CompatHelper.main(ENV, config)
```
