@testset "get_local_clone" begin
    apply([git_clone_patch, cd_patch]) do
        options = CompatHelper.Options()
        local_path = CompatHelper.get_local_clone(
            GitForge.GitHub.GitHubAPI(; token=GitHub.Token("token")),
            GitHubActions(),
            GitHub.Repo(; full_name="foobar");
            options,
        )
        @test local_path isa String
    end
end

@testset "get_project_deps" begin
    project = joinpath(@__DIR__, "deps", "Project.toml")

    deps = CompatHelper.get_project_deps(project; include_jll=true)
    @test length(deps) == 3
    deps = CompatHelper.get_project_deps(project; include_jll=false)
    @test length(deps) == 2
end

@testset "clone_all_registries" begin
    registry_1_url, registry_1_name = "https://github.com/JuliaRegistries/General",
    "General"
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

@testset "populate_dep_versions_from_reg!" begin
    # For this test, we will just use CompatHelper's own `Project.toml` file.
    project_file = joinpath(pkgdir(CompatHelper), "Project.toml")

    # Just for this test, we hardcode this list
    unregistered_stdlibs = [
        "Base64",
        "Dates",
        "Pkg",
        "UUIDs",
    ]

    @test ispath(project_file)
    @test isfile(project_file)
    for use_existing_registries in [true, false]
        options = CompatHelper.Options(;
            use_existing_registries,
        )
        deps = CompatHelper.get_project_deps(project_file)
        for dep in deps
            @test dep.latest_version === nothing
        end
        CompatHelper.populate_dep_versions_from_reg!(deps; options)
        for dep in deps
            if !(dep.package.name in unregistered_stdlibs)
                @test dep.latest_version isa VersionNumber
                @test dep.latest_version > v"0"
            end
        end
    end
end
