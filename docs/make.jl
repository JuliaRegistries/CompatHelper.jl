using CompatHelper
using Documenter
using Documenter.Remotes: GitHub

DocMeta.setdocmeta!(CompatHelper, :DocTestSetup, :(using CompatHelper); recursive=true)

makedocs(;
    modules=[CompatHelper],
    authors="Dilum Aluthge, Brown Center for Biomedical Informatics, and contributors",
    repo=GitHub("JuliaRegistries/CompatHelper.jl"),
    sitename="CompatHelper.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaRegistries.github.io/CompatHelper.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Configuration Options" => "options.md",
        "Acknowledgements" => "acknowledgements.md",
        "Other Environments" => "other-environments.md",
        "TroubleShooting" => "troubleshooting.md",
    ],
)

deploydocs(; repo="github.com/JuliaRegistries/CompatHelper.jl")
