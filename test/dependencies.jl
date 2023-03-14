@testset "get_project_deps" begin
    @testset "no jll" begin
        apply([git_clone_patch, project_toml_patch, cd_patch]) do
            options = CompatHelper.Options()
            subdir = only(options.subdirs)
            deps = CompatHelper.get_project_deps(
                GitForge.GitHub.GitHubAPI(; token=GitHub.Token("token")),
                GitHubActions(),
                GitHub.Repo(; full_name="foobar");
                options=options,
                subdir=subdir,
            )

            @test length(deps) == 1
        end
    end

    @testset "include_jll" begin
        apply([git_clone_patch, project_toml_patch, cd_patch]) do
            options = CompatHelper.Options(; include_jll=true)
            subdir = only(options.subdirs)
            deps = CompatHelper.get_project_deps(
                GitForge.GitHub.GitHubAPI(; token=GitHub.Token("token")),
                GitHubActions(),
                GitHub.Repo(; full_name="foobar");
                options=options,
                subdir=subdir,
            )

            @test length(deps) == 2
        end
    end
end

@testset "clone_all_registries" begin
    registry_1_url, registry_1_name = "https://github.com/JuliaRegistries/General", "General"
    registry_2_url, registry_2_name = "https://github.com/JuliaRegistries/Test", "Test"

    # Use temporary DEPOT_PATH
    old_DEPOT_PATH = copy(DEPOT_PATH)
    empty!(DEPOT_PATH)
    push!(DEPOT_PATH, tempdir())

    CompatHelper.clone_all_registries([
        Pkg.RegistrySpec(; name=registry_1_name, url=registry_1_url),
        Pkg.RegistrySpec(; name=registry_2_name, url=registry_2_url),
    ]) do registries

        @test length(registries) == 2
        @test contains(registry_1_name, registries[1].name)
        @test contains(registry_2_name, registries[2].name)
    end

    # Reset DEPOT_PATH
    empty!(DEPOT_PATH)
    append!(DEPOT_PATH, old_DEPOT_PATH)
end

@testset "get_latest_version_from_registries!" begin
    packageA = "PackageA"
    packageB = "PackageB"
    packageC = "PackageC"

    deps = Set{CompatHelper.DepInfo}([
        # No version specified
        CompatHelper.DepInfo(CompatHelper.Package(packageA, UUID(0))),

        # Version is less than what is in registry
        CompatHelper.DepInfo(
            CompatHelper.Package(packageB, UUID(1)); latest_version=VersionNumber(1)
        ),

        # Version is greater than what is in registry
        CompatHelper.DepInfo(
            CompatHelper.Package(packageC, UUID(2)); latest_version=VersionNumber("3")
        ),
    ])

    apply([clone_all_registries_patch, rm_patch]) do
        result = CompatHelper.get_latest_version_from_registries!(
            deps, Vector{Pkg.RegistrySpec}(); options=CompatHelper.Options()
        )

        @test length(result) == 3

        for res in result
            if res.package.name == packageA
                @test res.latest_version == VersionNumber("1")
            elseif res.package.name == packageB
                @test res.latest_version == VersionNumber("2")
            elseif res.package.name == packageC
                @test res.latest_version == VersionNumber("3")
            end
        end
    end
end

@testset "get_existing_registries!" begin
    packageA = "PackageA"
    packageB = "PackageB"
    packageC = "PackageC"

    deps = Set{CompatHelper.DepInfo}([
        # No version specified
        CompatHelper.DepInfo(CompatHelper.Package(packageA, UUID(0))),

        # Version is less than what is in registry
        CompatHelper.DepInfo(
            CompatHelper.Package(packageB, UUID(1)); latest_version=VersionNumber(1)
        ),

        # Version is greater than what is in registry
        CompatHelper.DepInfo(
            CompatHelper.Package(packageC, UUID(2)); latest_version=VersionNumber("3")
        ),
    ])

    result = CompatHelper.get_existing_registries!(
        deps, joinpath(@__DIR__, "deps"); options=CompatHelper.Options()
    )

    @test length(result) == 3

    for res in result
        if res.package.name == packageA
            @test res.latest_version == VersionNumber("1")
        elseif res.package.name == packageB
            @test res.latest_version == VersionNumber("2")
        elseif res.package.name == packageC
            @test res.latest_version == VersionNumber("3")
        end
    end
end
