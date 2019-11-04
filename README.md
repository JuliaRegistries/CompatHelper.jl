# CompatHelper

[![Build Status](https://travis-ci.com/bcbi/CompatHelper.jl.svg?branch=master)](https://travis-ci.com/bcbi/CompatHelper.jl)
[![Codecov](https://codecov.io/gh/bcbi/CompatHelper.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/bcbi/CompatHelper.jl)

CompatHelper is a Julia package that helps you keep your `[compat]` entries up-to-date.

Whenever one of your package's dependencies releases a new version, CompatHelper opens a pull request on your repository that modifies your `[compat]` entry to reflect the newly released version.

## Installation

The easiest way to use CompatHelper is to install it as a GitHub Action.

To install CompatHelper as a GitHub Action on your repository:

1. Go to the GitHub page for your repository.
2. Click on the "Actions" tab.
3. If you have never set up any GitHub Actions on your repository, you will be brought to a page that says "Get started with GitHub Actions". In the top right-hand corner, click on the button that says "Skip this: Set up a workflow yourself". Then go to step 5.
4. If you have previously set up a GitHub Action on your repository, you will be brought to a page that says "All workflows" and has a list of all of the GitHub Actions workflows on your repository. Click on the "New workflow" button. Then, in the top right-hand corner, click on the button that says "Skip this: Set up a workflow yourself". Then go to step 5.
5. An editor will open with some content pre-populated by GitHub. Delete all of the pre-populated content.
6. Copy the content from the [`.github/workflows/CompatHelper.yml`](.github/workflows/CompatHelper.yml) file in the CompatHelper.jl repository and paste it into the editor.
7. Name the file `CompatHelper.yml`. (The full path to the file should be `.github/workflows/CompatHelper.yml`.)
8. In the top right-hand corner, click on the green "Start commit" button, and then click on the green "Commit new file" button.

CompatHelper is now installed as a GitHub Action on your repository.
