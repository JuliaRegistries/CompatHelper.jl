```@meta
CurrentModule = CompatHelper
```

# Troubleshooting

Here are some tips for troubleshooting CompatHelper

## CompatHelper workflow file

The first step is to update your CompatHelper workflow file, which is usually
located  in your repository at `.github/workflows/CompatHelper.yml.` Make sure
that this file exactly matches the contents of the file located at
https://github.com/JuliaRegistries/CompatHelper.jl/blob/master/.github/workflows/CompatHelper.yml

## Manifest files

If CompatHelper is still failing, try deleting the following files (if they
exist):
- `/Manifest.toml`
- `/test/Manifest.toml`
- `/JuliaManifest.toml`
- `/test/JuliaManifest.toml`

If you continue to experience errors, try deleting all `Manifest.toml` files
and `JuliaManifest.toml` files from your repository.
