```@meta
CurrentModule = CompatHelper
```

# Self-Hosting and Other Environments

It is possible to run CompatHelper on custom infrastructure.
This includes GitHub Enterprise, public GitLab, or even private GitLab.
To use any of these you need to just create and pass along the CI Configuration.
The example below would be for GitHub Enterprise:

```julia
using CompatHelper

ENV["GITHUB_TOKEN"] = "GitHub Enterprise Personal Access Token"
ENV["GITHUB_REPOSITORY"] = "Organization/Repository"

config = CompatHelper.GitHubActions(;
    username="GitHub Enterprise Username",
    email="GitHub Enterprise Email",
    api_hostname="https://github.company.com/api/v3",
    clone_hostname="github.company.com"
)

CompatHelper.main(ENV, config)
```

You can also create your own configurations, for example TeamCity:

```julia
using CompatHelper

config = CompatHelper.GitHubActions(;
    username="TeamCity Username"
    email="TeamCity Email",
    api_hostname="http://<TeamCity Server host>:<port>/app/rest/server"
    clone_hostname="http://<TeamCity Server host>"
)

CompatHelper.main(ENV, config)
```
