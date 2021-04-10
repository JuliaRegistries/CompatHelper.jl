```@meta
CurrentModule = CompatHelper
```

# Configuration Options

## Packages in subdirectories

By default, CompatHelper expects your git repository to contain a single package, and that the `Project.toml` for that package exists in the top-level directory. You can indicate that you want CompatHelper to process one or many packages that exist in subdirectories of the git repository by passing the `subdirs` keyword to the main function. For example:
```julia
CompatHelper.main(; subdirs = ["", "Subdir1", "very/deeply/nested/Subdir2"])
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

CompatHelper.main(; registries = my_registries)
```

## Overriding the default branch

By default, CompatHelper will open pull requests against your repository's default branch. If you would like to override this behavior, set the `master_branch` keyword argument. For example:
```julia
CompatHelper.main(; master_branch = "my-custom-branch")
```
