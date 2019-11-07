# CompatHelper

[![Build Status](https://travis-ci.com/bcbi/CompatHelper.jl.svg?branch=master)](https://travis-ci.com/bcbi/CompatHelper.jl)
[![Codecov](https://codecov.io/gh/bcbi/CompatHelper.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/bcbi/CompatHelper.jl)

CompatHelper is a Julia package that helps you keep your `[compat]` entries up-to-date.

Whenever one of your package's dependencies releases a new version, CompatHelper opens a pull request on your repository that modifies your `[compat]` entry to reflect the newly released version.

## Installation

The easiest way to use CompatHelper is to install it as a GitHub Action.

To install CompatHelper as a GitHub Action on your repository:

1. Go to the GitHub page for your repository.


2. Click on the "Actions" tab. (If you don't see the "Actions" tab, follow the instructions [here](#actions-setup).)
3. If you have never set up any GitHub Actions on your repository, you will be brought to a page that says "Get started with GitHub Actions". In the top right-hand corner, click on the button that says "Skip this: Set up a workflow yourself". Then go to step 5.
4. If you have previously set up a GitHub Action on your repository, you will be brought to a page that says "All workflows" and has a list of all of the GitHub Actions workflows on your repository. Click on the "New workflow" button. Then, in the top right-hand corner, click on the button that says "Skip this: Set up a workflow yourself". Then go to step 5.
5. An editor will open with some content pre-populated by GitHub. Delete all of the pre-populated content.
6. Copy the content from the [`.github/workflows/CompatHelper.yml`](.github/workflows/CompatHelper.yml) file in the CompatHelper.jl repository and paste it into the editor.
7. Name the file `CompatHelper.yml`. (The full path to the file should be `.github/workflows/CompatHelper.yml`.)
8. In the top right-hand corner, click on the green "Start commit" button, and then click on the green "Commit new file" button.

CompatHelper is now installed as a GitHub Action on your repository.


## Actions Setup
* Sign up for the beta of GitHub Actions from https://github.com/features/actions 
* Open the specific repository, navigate to the Settings tab, click Actions option, check if the Actions is enabled for this repository.


## Updating `Manifest.toml` files after updating compat information

If you check in `Manifest.toml` file(s), the PR created by default CompatHelper setup does not run CI with the latest versions of the dependencies.  In this case, it may be a good idea to run `Pkg.update()` via CompatHelper.  This can be done simply using the following snippet instead `run: julia -e 'using CompatHelper; CompatHelper.main()'`:

```yaml
run: >-
  julia -e '
  using CompatHelper;
  CompatHelper.main() do;
      run(`julia --project=test -e "import Pkg; Pkg.instantiate(); Pkg.update()"`);
      run(`julia --project=docs -e "import Pkg; Pkg.instantiate(); Pkg.update()"`);
  end
  '
```

This setup updates `test/Manifest.toml` and `docs/Manifest.toml` before CompatHelper creates a commit for the pull request.

This snippet uses `>-` to specify a long one-liner command using multi-line code (i.e., the shell does not see the newline characters after `;`).  Note that every line must ends with `;` when using `>-`.  Do not use `'` inside (outer) Julia code since it is used to quote the command line option `-e '...'`.

A full example is available here: https://github.com/tkf/Kaleido.jl/blob/master/.github/workflows/CompatHelper.yml

## Acknowledgements

- This work was supported in part by National Institutes of Health grants U54GM115677, R01LM011963, and R25MH116440. The content is solely the responsibility of the authors and does not necessarily represent the official views of the National Institutes of Health.
