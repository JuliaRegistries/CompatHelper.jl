```@meta
CurrentModule = CompatHelper
```

```@autodocs
Modules = [CompatHelper]
```

# [CompatHelper.jl](https://github.com/JuliaRegistries/CompatHelper.jl)

CompatHelper is a Julia package that helps you keep your `[compat]` entries up-to-date.
Whenever one of your package's dependencies releases a new breaking version, CompatHelper opens a pull request on your repository that modifies your `[compat]` entry to reflect the newly released version.
We would like to eventually add Julia support to [Dependabot](https://dependabot.com).
If you would like to help with adding Julia support to Dependabot, join us in the `#dependabot` channel on the [Julia Language Slack](https://julialang.org/slack/).

## Installation
### GitHub
Create a file at `.github/workflows/CompatHelper.yml` with the following contents,

```yaml
name: CompatHelper
on:
  schedule:
    - cron: '0 0 * * *'  # Everyday at midnight
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
          COMPATHELPER_PRIV: ${{ secrets.COMPATHELPER_PRIV }}
        run: julia -e 'using CompatHelper; CompatHelper.main()'
```

#### Creating SSH Key
If you use GitHub Actions to either test your packge using continuous integration, or build and deploy documentation you will need to create an SSH deploy key.
If you wish to reuse an existing SSH key simplify modify the workflow above environment variable to use `COMPATHELPER_PRIV: ${{ secrets.DOCUMENTER_KEY }}`.
Otherwise follow the below instructions to generate a new key,

1. Generate a new SSH key
   1. `ssh-keygen -m PEM -N "" -f compathelper_key`
2. Create a new GitHub secret
   1. Copy the private key, `cat compathelper_key`
   2. Go to your repositories settings page
   3. Select `Secrets`, and `New Repository Secret`
   4. Name the secret `COMPATHELPER_PRIV`, paste the copied private key
3. Create a new deploy key
   1. Copy the public key, `cat compathelper_key.pub`
   2. Go to your repositories settings page
   3. Select `Deploy Keys`, and `Add Deploy Key`
   4. Name the deploy key `COMPATHELPER_PUB`, paste in the copied public key
   5. Ensure that the key has `Write Access`
4. Cleanup the SSH key from your computer, `rm -f compathelper_key compathelper_key.pub`
