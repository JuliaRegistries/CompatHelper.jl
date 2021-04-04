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

## Custom pre-commit hooks

CompatHelper supports running a custom function (called a "precommit hook") just before commiting changes. To provide a precommit hook, simple pass a zero-argument function as the first argument to `CompatHelper.main`.

## Default precommit hook

If you do not specify a precommit hook, CompatHelper will run the default precommit hook (`CompatHelper.update_manifests`), which updates all `Manifest.toml` files in your repository.

## Examples

### Example 1: Disable all precommit hooks

If you want to disable all precommit hooks, simply pass a dummy function that does nothing:

```yaml
run: julia -e '
  using CompatHelper;
  CompatHelper.main( () -> () );'
```

### Example 2: Print a logging message

You can add functionality by passing your own zero-argument function to `CompatHelper.main`, like so:

```yaml
run: julia -e '
  using CompatHelper;
  CompatHelper.main() do;
    CompatHelper.update_manifests();
    println("I did it!");
  end;'
```

This snippet uses `;` to specify the ends of lines, because according to YAML, the entire block of Julia code is a single line.
Also to note is that you cannot use `'` inside of your Julia command, since it's used to quote the Julia code.

A full example is available [here](https://github.com/tkf/Kaleido.jl/blob/42f8125f42413ef21160575d870819bba33296d5/.github/workflows/CompatHelper.yml).

### Example 3: Only update the `Manifest.toml` in the root of the repository

The following snippet tells CompatHelper to update the `Manifest.toml` file in the root of the repository but not any of the other `Manifest.toml` files. So, for example, `/Manifest.toml` will be updated, but `/docs/Manifest.toml`, `/examples/Manifest.toml`, and `/test/Manifest.toml` will not be updated.

```yaml
run: julia -e 'using CompatHelper; CompatHelper.main( (; registries) -> CompatHelper._update_manifests(String[pwd()]; registries = registries, delete_old_manifest = true) )'
```

If the keyword argument `delete_old_manifest` is set to true, as in the above example, then CompatHelper
updates the Manifest.toml file by deleting the Manifest and running `Pkg.update()` in order to generate a new
one. If `delete_old_manifest=false`, then CompatHelper runs `Pkg.update()` without first deleting the Manifest.

## Overriding the default branch

By default, CompatHelper will open pull requests against your repository's default branch. If you would like to override this behavior, set the `master_branch` keyword argument. For example:
```julia
CompatHelper.main(; master_branch = "my-custom-branch")
```
