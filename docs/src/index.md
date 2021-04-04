```@meta
CurrentModule = CompatHelper
```

# [CompatHelper.jl](https://github.com/JuliaRegistries/CompatHelper.jl)

CompatHelper is a Julia package that helps you keep your `[compat]` entries up-to-date.

Whenever one of your package's dependencies releases a new breaking version, CompatHelper opens a pull request on your repository that modifies your `[compat]` entry to reflect the newly released version.

We would like to eventually add Julia support to [Dependabot](https://dependabot.com), at which point we will deprecate CompatHelper in favor of Dependabot. If you would like to help with adding Julia support to Dependabot, join us in the `#dependabot` channel on the [Julia Language Slack](https://julialang.org/slack/).

## Installation, step 1: Create the workflow file

Create a file at `.github/workflows/CompatHelper.yml` with the following contents:

```@eval
import CompatHelper
import Markdown

const root_directory = dirname(dirname(pathof(CompatHelper)))
const workflow_dir = joinpath(root_directory, ".github", "workflows")
const workflow_filename = joinpath(workflow_dir, "CompatHelper.yml")
const workflow_filecontents = read(workflow_filename, String)
const str = string("```yaml\n", strip(workflow_filecontents), "\n```")
const md = Markdown.parse(str)
return md
```

Note: Julia is available by default in the GitHub Actions virtual environments.
Therefore, you do not need to manually install Julia.

CompatHelper is now installed as a GitHub Action on your repository. But wait: do you fall into any of the following categories:
1. You use GitHub Actions to test your package using continuous integration (CI).
2. You use GitHub Actions to build and deploy the documentation for your package.

If you do not fall into any of those categories, then you are done! There is nothing more that you need to do.

But if you do fall into one or more of those categories, then you also need to set up an SSH deploy key for CompatHelper to use. Read on:

## Installation, step 2: Set up the SSH deploy key

*Note: if you already have an SSH deploy key set up in a secret, e.g. `DOCUMENTER_KEY` or `FRANKLIN_PRIV`, you can reuse it. See the "Advanced notes" section below.*

### Motivation

The default CompatHelper setup has one flaw: the pull requests that CompatHelper opens will not trigger any other GitHub Actions.

Consider the following situations:
1. You use GitHub Actions to test your package using continuous integration (CI).
2. You use GitHub Actions to build and deploy the documentation for your package.

If any of those situations apply to you, then you will need to set up an SSH deploy key for CompatHelper. Once you have set up an SSH deploy key for CompatHelper, the pull requests that CompatHelper opens will trigger all of the usual GitHub Actions.

If none of those situations apply to you, then you don't need to set up an SSH deploy key for CompatHelper.

### Instructions for setting up the SSH deploy key

It is easy to set up an SSH deploy key for CompatHelper. Here are the instructions:
1. `ssh-keygen -N "" -f compathelper_key`
2. `cat compathelper_key # This is the private key. Copy this to your clipboard.`
3. Go to the GitHub page for your package's repository, click on the **Settings** tab, then click on **Secrets**, and then click on **New repository secret**. Name the secret `COMPATHELPER_PRIV`. For the contents, paste in the private key that you copied in the previous step.
4. `cat compathelper_key.pub # This is the public key. Copy this to your clipboard.`
5. Go to the GitHub page for your package's repository, click on the **Settings** tab, then click on **Deploy keys**, and then click on **Add deploy key**. Name the deploy key `COMPATHELPER_PUB`. For the contents, paste in the public key that you copied in the previous step. Make sure that you give the key **write access**.
6. `rm -f compathelper_key compathelper_key.pub`

### Advanced notes

When you supply the private key, you can either provide the raw private key itself (as we did above), or you can provide the Base64-encoded form of the private key.

For example, if you already have a Base64-encoded private key saved as a secret, you can re-use it. If e.g. the secret is named `DOCUMENTER_KEY`, then simply replace the line that looks like this:
```yaml
COMPATHELPER_PRIV: ${{ secrets.COMPATHELPER_PRIV }}
```

with this line:
```yaml
COMPATHELPER_PRIV: ${{ secrets.DOCUMENTER_KEY }}
```
