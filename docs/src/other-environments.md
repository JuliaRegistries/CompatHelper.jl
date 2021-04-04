```@meta
CurrentModule = CompatHelper
```

# Self-Hosting and Other Environments

It's possible to run CompatHelper on your infrastructure in case of GitHub Enterprise or other setups.

Basically it should be all configurable by passing values to `CompatHelper.main()` function.
To run it on GitHub Enterprise, e.g. on address `github.company.com` you can do
```julia
using CompatHelper

ENV["GITHUB_TOKEN"] = "github access token"
ENV["GITHUB_REPOSITORY"] = "org/repo"
username = "github user name that matches the access token"
email = "email address"

CompatHelper.main(CompatHelper.update_manifests,
                  ENV,
                  CompatHelper.GitHubActions(username, email);
                  hostname_for_api = "https://github.company.com/api/v3",
                  hostname_for_clone = "github.company.com")
```

To run it on TeamCity instead of GitHub Actions, you need to specify the `ci_cfg` parameter, e.g. like this.
```julia
using CompatHelper
CompatHelper.main(CompatHelper.update_manifests,
    ENV,
    CompatHelper.TeamCity(<your bot github account username>, <your bot github email>)
    )
```
Because of high configurability of TeamCity it's advised to pass the TeamCity structure explicitly without usage of the
`auto_detect_ci_service` function, which is suitable for some simpler setups.
