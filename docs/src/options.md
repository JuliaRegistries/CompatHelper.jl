```@meta
CurrentModule = CompatHelper
```

# Configuration Options

## Packages in subdirectories

By default, CompatHelper expects your git repository to contain a single package, and that the `Project.toml` for that package exists in the top-level directory. You can indicate that you want CompatHelper to process one or many packages that exist in subdirectories of the git repository by passing the `subdirs` keyword to the main function. For example:
```julia
CompatHelper.main(; subdirs=["", "Subdir1", "very/deeply/nested/Subdir2"])
```
Note that the convention for specifying a top-level directory in the `subdirs` keyword is `[""]`

## Custom registries

To use a list of custom registries instead of the General registry, use the `registries` keyword argument. For example:
```julia
my_registries = [Pkg.RegistrySpec(name = "General",
                                  uuid = "23338594-aafe-5451-b93e-139f81909106",
                                  url = "https://github.com/JuliaRegistries/General.git"),
                 Pkg.RegistrySpec(name = "BioJuliaRegistry",
                                  uuid = "ccbd2cc2-2954-11e9-1ccf-f3e7900901ca",
                                  url = "https://github.com/BioJulia/BioJuliaRegistry.git")]

CompatHelper.main(; registries=my_registries)
```

Using the above option will clone the registries, but if you want to use already existing registries,
you can use the `use_existing_registries` option. This will use all the registries present in the user depot,
defined as the first entry of the `DEPOT_PATH` by the [Pkg manual](https://pkgdocs.julialang.org/v1/glossary/).
```julia
CompatHelper.main(; use_existing_registries=true)
```

If you want to use a different location, you can specify that using the `depot` keyword.
Note that the directroy indicated by `depot` should contain a subdirectory named `registries` where the registries
are stored in order to reproduce the structure of the Julia depot.

!!! info
    Using the above mentioned `use_existing_registries` can be used in conjunction with the [`add-julia-registry`](https://github.com/julia-actions/add-julia-registry) GitHub action to easily add custom private registries in GitHub Actions CI.

## Overriding the default branch

By default, CompatHelper will open pull requests against your repository's default branch. If you would like to override this behavior, set the `master_branch` keyword argument. For example:
```julia
CompatHelper.main(; master_branch="my-custom-branch")
```

## EntryType

Define how you want to handle compat entries.

- `KeepEntry`: Default value, this will keep the existing compat entry for a project and add the new one in addition.
- `DropEntry`: Choose this to drop the existing compat entry and replace it with the new one.

`KeepEntry` is the default, but if you like to use `DropEntry`, you can do the following:
```julia
CompatHelper.main(; entry_type=DropEntry())
```

## Unsubscribe from Pull Requests

When a compat Pull Request is created, the user/bot that created the PR will be unsubscribed from the PR that it just created. This is needed in some situations to lower the amount of noise a bot may generate by being subscribed to a PR as any comments/activity will trigger an email/notification for that bot.

Currently this only works for GitLab as it doesn't seem like the GitHub API has an endpoint for this.
```julia
CompatHelper.main(; ubsub_from_prs=true)
```

## CC User

When a compat Pull Request is created, you might want the user that generated the PR to be notified which should subscribe them to the PR. This can be used in situations where a user manually triggers a CompatHelper run on GitLab, but has it set up so that the PR is created by a bot. In this case, the user would like to be subscribed to the new PRs.

This will use the `GITHUB_ACTOR` or `GITLAB_USER_LOGIN` environment variables to determine which user to mention.

```julia
CompatHelper.main(; cc_user=true)
```
