# CompatHelper

[![Build Status](https://travis-ci.com/JuliaRegistries/CompatHelper.jl.svg?branch=master)](https://travis-ci.com/JuliaRegistries/CompatHelper.jl)
[![Codecov](https://codecov.io/gh/JuliaRegistries/CompatHelper.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaRegistries/CompatHelper.jl)

CompatHelper is a Julia package that helps you keep your `[compat]` entries up-to-date.

Whenever one of your package's dependencies releases a new version, CompatHelper opens a pull request on your repository that modifies your `[compat]` entry to reflect the newly released version.

## Table of Contents

* [1. Installation](#1-installation)
  * [1.1. Create the workflow file (required)](#11-create-the-workflow-file-required)
  * [1.2. Set up the SSH deploy key (optional)](#12-set-up-the-ssh-deploy-key-optional)
* [2. Configuration options](#2-configuration-options)
  * [2.1. Packages in subdirectories](#21-packages-in-subdirectories)
  * [2.2. Custom registries](#22-custom-registries)
  * [2.3. Custom pre-commit hooks](#23-custom-pre-commit-hooks)
  * [2.4. Overriding the default branch](#24-overriding-the-default-branch)
* [3. Troubleshooting](#3-troubleshooting)
* [4. Self-hosting and other environments](#4-self-hosting-and-other-environments)
* [5. Acknowledgements](#5-acknowledgements)

## 1. Installation

### 1.1 Create the workflow file (required)

Create a file at `.github/workflows/CompatHelper.yml` with the following contents:
```yaml
name: CompatHelper
on:
  schedule:
    - cron: '00 00 * * *'
  workflow_dispatch:
jobs:
  CompatHelper:
    runs-on: ubuntu-latest
    steps:
      - name: Pkg.add("CompatHelper")
        run: julia -e 'using Pkg; Pkg.add("CompatHelper")'
      - name: CompatHelper.main()
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          COMPATHELPER_PRIV: ${{ secrets.COMPATHELPER_PRIV }}  # optional
        run: julia -e 'using CompatHelper; CompatHelper.main()'
```

CompatHelper is now installed as a GitHub Action on your repository. But wait: do you fall into any of the following categories:
1. You use GitHub Actions to test your package using continuous integration (CI).
2. You use GitHub Actions to build and deploy the documentation for your package.

If you do not fall into any of those categories, then you are done! There is nothing more that you need to do.

But if you do fall into one or more of those categories, then you also need to set up an SSH deploy key for CompatHelper to use. Read on:

### 1.2. Set up the SSH deploy key (optional)

*Note: if you already have an SSH deploy key set up in a secret, e.g. `DOCUMENTER_KEY` or `FRANKLIN_PRIV`, you can reuse it. See the "Advanced notes" section below.*

#### 1.2.1. Motivation

The default CompatHelper setup has one flaw: the pull requests that CompatHelper opens will not trigger any other GitHub Actions.

Consider the following situations:
1. You use GitHub Actions to test your package using continuous integration (CI).
2. You use GitHub Actions to build and deploy the documentation for your package.

If any of those situations apply to you, then you will need to set up an SSH deploy key for CompatHelper. Once you have set up an SSH deploy key for CompatHelper, the pull requests that CompatHelper opens will trigger all of the usual GitHub Actions.

If none of those situations apply to you, then you don't need to set up an SSH deploy key for CompatHelper. 

#### 1.2.2. Instructions for setting up the SSH deploy key

It is easy to set up an SSH deploy key for CompatHelper. Here are the instructions:
1. `ssh-keygen -N "" -f compathelper_key`
2. `cat compathelper_key # This is the private key. Copy this to your clipboard.`
3. Go to the GitHub page for your package's repository, click on the **Settings** tab, then click on **Secrets**, and then click on **Add new secret**. Name the secret `COMPATHELPER_PRIV`. For the contents, paste in the private key that you copied in the previous step.
4. `cat compathelper_key.pub # This is the public key. Copy this to your clipboard.`
5. Go to the GitHub page for your package's repository, click on the **Settings** tab, then click on **Deploy keys**, and then click on **Add deploy key**. Name the deploy key `COMPATHELPER_PUB`. For the contents, paste in the public key that you copied in the previous step. Make sure that you give the key **write access**.
6. `rm -f compathelper_key compathelper_key.pub`

#### 1.2.3. Advanced notes

When you supply the private key, you can either provide the raw private key itself (as we did above), or you can provide the Base64-encoded form of the private key.

For example, if you already have a Base64-encoded private key saved as a secret, you can re-use it. If e.g. the secret is named `DOCUMENTER_KEY`, then simply replace the line that looks like this:
```yaml
COMPATHELPER_PRIV: ${{ secrets.COMPATHELPER_PRIV }}
```

with this line:
```yaml
COMPATHELPER_PRIV: ${{ secrets.DOCUMENTER_KEY }}
```

## 2. Configuration options

### 2.1. Packages in subdirectories

By default, CompatHelper expects your git repository to contain a single package, and that the `Project.toml` for that package exists in the top-level directory. You can indicate that you want CompatHelper to process one or many packages that exist in subdirectories of the git repository by passing the `subdirs` keyword to the main function. For example:
```julia
CompatHelper.main(; subdirs = ["", "Subdir1", "very/deeply/nested/Subdir2"])
```
Note that the convention for specifying a top-level directory in the `subdirs` keyword is `[""]`

### 2.2. Custom registries

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

### 2.3. Custom pre-commit hooks

CompatHelper supports running a custom function (called a "precommit hook") just before commiting changes. To provide a precommit hook, simple pass a zero-argument function as the first argument to `CompatHelper.main`.

#### 2.3.1. Default precommit hook

If you do not specify a precommit hook, CompatHelper will run the default precommit hook (`CompatHelper.update_manifests`), which updates all `Manifest.toml` files in your repository.

#### 2.3.2. Examples

##### Example 1: Disable all precommit hooks

If you want to disable all precommit hooks, simply pass a dummy function that does nothing:

```yaml
run: julia -e '
  using CompatHelper;
  CompatHelper.main( () -> () );'
```

##### Example 2: Print a logging message

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

##### Example 3: Only update the `Manifest.toml` in the root of the repository

The following snippet tells CompatHelper to update the `Manifest.toml` file in the root of the repository but not any of the other `Manifest.toml` files. So, for example, `/Manifest.toml` will be updated, but `/docs/Manifest.toml`, `/examples/Manifest.toml`, and `/test/Manifest.toml` will not be updated.

```yaml
run: julia -e 'using CompatHelper; CompatHelper.main( (; registries) -> CompatHelper._update_manifests(String[pwd()]; registries = registries, delete_old_manifests = true) )'
```

If the keyword argument `delete_old_manifests` is set to true, as in the above example, then CompatHelper
updates the Manifest.toml file by deleting the Manifest and running `Pkg.update()` in order to generate a new
one. If `delete_old_manifests=false`, then CompatHelper runs `Pkg.update()` without first deleting the Manifest.

### 2.4. Overriding the default branch

By default, CompatHelper will open pull requests against your repository's default branch. If you would like to override this behavior, set the `master_branch` keyword argument. For example:
```julia
CompatHelper.main(; master_branch = "my-custom-branch")
```

## 3. Troubleshooting

If CompatHelper is failing despite everything being setup correctly following the previous instructions, try to delete the `Manifest.toml` file from the `src` folder (and from the `test` folder if any). See this [issue](https://github.com/bcbi/CompatHelper.jl/issues/201) for more details.

## 4. Self hosting and other environments

It's possible to run CompatHelper on your infrastructure in case of GitHub Enterprise or other setups.

Basically it should be all configurable by passing values to `CompatHelper.main()` function.
To run it on GitHub Enterprise, e.g. on address `github.company.com` you can do
```julia
using CompatHelper
CompatHelper.main(; hostname_for_api="https://github.company.com/api/v3",
                    hostname_for_clone="github.company.com")
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

## 5. Acknowledgements

CompatHelper was originally created by the [Brown Center for Biomedical Informatics](https://github.com/bcbi) at Brown University.

This work was supported in part by National Institutes of Health grants U54GM115677, R01LM011963, and R25MH116440. The content is solely the responsibility of the authors and does not necessarily represent the official views of the National Institutes of Health.
