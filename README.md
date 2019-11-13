# CompatHelper

[![Build Status](https://travis-ci.com/bcbi/CompatHelper.jl.svg?branch=master)](https://travis-ci.com/bcbi/CompatHelper.jl)
[![Codecov](https://codecov.io/gh/bcbi/CompatHelper.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/bcbi/CompatHelper.jl)

CompatHelper is a Julia package that helps you keep your `[compat]` entries up-to-date.

Whenever one of your package's dependencies releases a new version, CompatHelper opens a pull request on your repository that modifies your `[compat]` entry to reflect the newly released version.

## Installation

The easiest way to use CompatHelper is to install it as a GitHub Action.

To install CompatHelper as a GitHub Action on your repository:

1. Go to the GitHub page for your repository.
2. Click on the "Actions" tab. (If you don't see the "Actions" tab, follow the instructions [here](#actions-setup).) The Action tab is across the top as shown in this screenshot:
![action](readme_images/action_tab.png)
3. If you have never set up any GitHub Actions on your repository, you will be brought to a page that says "Get started with GitHub Actions". In the top right-hand corner, click on the button that says "Skip this: Set up a workflow yourself". Then go to step 5.
4. If you have previously set up a GitHub Action on your repository, you will be brought to a page that says "All workflows" and has a list of all of the GitHub Actions workflows on your repository. Click on the "New workflow" button. Then, in the top right-hand corner, click on the button that says "Skip this: Set up a workflow yourself". Then go to step 5.
5. An editor will open with some content pre-populated by GitHub. Delete all of the pre-populated content.
6. Copy the content from the [`.github/workflows/CompatHelper.yml`](.github/workflows/CompatHelper.yml) file in the CompatHelper.jl repository and paste it into the editor.
7. Name the file `CompatHelper.yml`. (The full path to the file should be `.github/workflows/CompatHelper.yml`.)
8. In the top right-hand corner, click on the green "Start commit" button, and then click on the green "Commit new file" button.

CompatHelper is now installed as a GitHub Action on your repository.

## Overriding the default branch

By default, CompatHelper will open pull requests against your repository's default branch. If you would like to override this behavior, set the `master_branch` keyword argument. For example:
```julia
CompatHelper.main(; master_branch = "my-custom-branch")
```

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

## Actions setup
* Sign up for the beta of GitHub Actions from https://github.com/features/actions
* Open the specific repository, navigate to the Settings tab, click Actions option, check if the Actions is enabled for this repository.


## Custom pre-commit hooks

CompatHelper supports running a custom function just before commiting changes.
By default, this function updates any `Manifest.toml` files in your repository to reflect new compatibility bounds.
If you want to extend this behaviour, you can pass your own zero-argument function to `CompatHelper.main`, like so:

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

A full example is available here: https://github.com/tkf/Kaleido.jl/blob/master/.github/workflows/CompatHelper.yml

If you want to disable the default behavior, simply pass a dummy function that does nothing:

```yaml
run: julia -e '
  using CompatHelper;
  CompatHelper.main( () -> () );'
```

## Acknowledgements

- This work was supported in part by National Institutes of Health grants U54GM115677, R01LM011963, and R25MH116440. The content is solely the responsibility of the authors and does not necessarily represent the official views of the National Institutes of Health.
