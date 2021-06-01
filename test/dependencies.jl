@testset "add_compat_section!" begin
    @testset "exists" begin
        d = Dict("compat" => "foobar")
        CompatHelper.add_compat_section!(d)

        @test haskey(d, "compat")
    end

    @testset "dne" begin
        d = Dict()
        CompatHelper.add_compat_section!(d)

        @test haskey(d, "compat")
    end
end

@testset "get_project_deps" begin
    @testset "no jll" begin
        apply([git_clone_patch, project_toml_patch]) do
            deps = CompatHelper.get_project_deps(
                GitForge.GitHub.GitHubAPI(), "", GitHub.Repo(; full_name="foobar")
            )

            @test length(deps) == 1
        end
    end

    @testset "include_jll" begin
        apply([git_clone_patch, project_toml_patch]) do
            deps = CompatHelper.get_project_deps(
                GitForge.GitHub.GitHubAPI(),
                "",
                GitHub.Repo(; full_name="foobar");
                include_jll=true,
            )

            @test length(deps) == 2
        end
    end
end

@testset "clone_all_registries" begin
    registry_1_name = "foobar"
    registry_2_name = "bizbaz"

    apply([mktempdir_patch, git_clone_patch]) do
        resp = CompatHelper.clone_all_registries([
            Pkg.RegistrySpec(; name=registry_1_name, url=""),
            Pkg.RegistrySpec(; name=registry_2_name, url=""),
        ])

        @test length(resp) == 2

        @test contains(resp[1], registry_1_name)
        @test contains(resp[2], registry_2_name)
        @test length(resp) == 2
    end
end

@testset "get_latest_version_from_registries!" begin
    packageA = "PackageA"
    packageB = "PackageB"
    packageC = "PackageC"

    deps = Set{CompatHelper.CompatEntry}([
        # No version specified
        CompatHelper.CompatEntry(CompatHelper.Package(packageA, UUID(0))),

        # Version is less than what is in registry
        CompatHelper.CompatEntry(
            CompatHelper.Package(packageB, UUID(1)); version_number=VersionNumber(1)
        ),

        # Version is greater than what is in registry
        CompatHelper.CompatEntry(
            CompatHelper.Package(packageC, UUID(2)); version_number=VersionNumber("3")
        ),
    ])
    apply([clone_all_registries_patch, rm_patch]) do
        result = CompatHelper.get_latest_version_from_registries!(
            deps, Vector{Pkg.RegistrySpec}()
        )

        @test length(result) == 3

        for res in result
            if res.package.name == packageA
                @test res.version_number == VersionNumber("1")
            elseif res.package.name == packageB
                @test res.version_number == VersionNumber("2")
            elseif res.package.name == packageC
                @test res.version_number == VersionNumber("3")
            end
        end
    end
end
