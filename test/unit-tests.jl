@testset "`version =` line in the workflow file" begin
    root_directory = dirname(dirname(@__FILE__))
    project_file = joinpath(root_directory, "Project.toml")
    version = Base.VersionNumber(TOML.parsefile(project_file)["version"])
    major_version = version.major
    @test major_version >= 1

    workflow_dir = joinpath(root_directory, ".github", "workflows")
    workflow_filename = joinpath(workflow_dir, "CompatHelper.yml")
    workflow_filecontents = read(workflow_filename, String)
    @test occursin(Regex("\\sversion = \"$(major_version)\"\n"), workflow_filecontents)
end

@testset "assert.jl" begin
    @test_nowarn CompatHelper.always_assert(true)
    @test CompatHelper.always_assert(true) isa Nothing
    @test CompatHelper.always_assert(true) === nothing
    @test @test_nowarn CompatHelper.always_assert(true) isa Nothing
    @test @test_nowarn CompatHelper.always_assert(true) === nothing
    @test_throws CompatHelper.AlwaysAssertionError CompatHelper.always_assert(false)
end

@testset "envdict.jl" begin
    a = "/foo/bar/baz"
    b = Dict(
        "PATH" => "/foo",
        "HTTP_PROXY" => "/bar",
        "HTTPS_PROXY" => "/baz",
        "JULIA_PKG_SERVER" => "/foobar",
    )
    c = CompatHelper._generate_env_dict(b; JULIA_DEPOT_PATH=a)
end

@testset "ci_service.jl" begin
    withenv("GITHUB_REPOSITORY" => "foo/bar") do
        @test CompatHelper.auto_detect_ci_service() isa CompatHelper.CIService
        @test CompatHelper.auto_detect_ci_service() isa CompatHelper.GitHubActions

        @test_throws ArgumentError CompatHelper.main(;
            keep_existing_compat=false, drop_existing_compat=false
        )
    end

    withenv("GITHUB_REPOSITORY" => nothing) do
        @test_throws ErrorException CompatHelper.auto_detect_ci_service()
    end

    ci_cfg = CompatHelper.TeamCity()

    @test ci_cfg.username == "github-actions[bot]"
    @test ci_cfg.email == "41898282+github-actions[bot]@users.noreply.github.com"

    withenv("GITHUB_REPOSITORY" => "foo/bar") do
        ci_cfg = CompatHelper.TeamCity("service_user", "service_user@company.com")
        @test CompatHelper.github_repository(ci_cfg) == "foo/bar"
        @test ci_cfg.username == "service_user"
        @test ci_cfg.email == "service_user@company.com"
    end
end

@testset "git.jl" begin
    @test CompatHelper.git_decide_master_branch(
        CompatHelper.DefaultBranch(), "  abcdefg  "
    ) == "abcdefg"

    @test CompatHelper.git_decide_master_branch(" abc ", " xyz ") == "abc"
end

@testset "new_versions.jl" begin
    @test_throws ArgumentError CompatHelper.old_compat_to_new_compat("", "", :abc)
end

@testset "pull_requests.jl" begin
    a = GitHub.Repo(
        Dict(
            "name" => "Foo",
            "full_name" => "Foo",
            "owner" => "Foo",
            "id" => 1,
            "url" => "Foo",
            "html_url" => "Foo",
            "fork" => false,
        ),
    )

    b = GitHub.Repo(
        Dict(
            "name" => "Foo",
            "full_name" => "Foo",
            "owner" => "Foo",
            "id" => 1,
            "url" => "Foo",
            "html_url" => "Foo",
            "fork" => false,
        ),
    )

    c = GitHub.Repo(
        Dict(
            "name" => "Foo",
            "full_name" => "Foo",
            "owner" => "Foo",
            "id" => 1,
            "url" => "Foo",
            "html_url" => "Foo",
            "fork" => true,
        ),
    )

    @test !CompatHelper._repos_are_the_same(a, nothing)
    @test !CompatHelper._repos_are_the_same(nothing, a)
    @test !CompatHelper._repos_are_the_same(nothing, nothing)
    @test CompatHelper._repos_are_the_same(a, a)
    @test CompatHelper._repos_are_the_same(a, b)
    @test !CompatHelper._repos_are_the_same(a, c)
    @test CompatHelper._repos_are_the_same(b, a)
    @test CompatHelper._repos_are_the_same(b, b)
    @test !CompatHelper._repos_are_the_same(b, c)
    @test !CompatHelper._repos_are_the_same(c, a)
    @test !CompatHelper._repos_are_the_same(c, b)
    @test CompatHelper._repos_are_the_same(c, c)
end

@testset "ssh_keys.jl" begin
    a = "-----BEGIN OPENSSH PRIVATE KEY-----\n12345\n-----END OPENSSH PRIVATE KEY-----" # good
    b = Base64.base64encode(a)
    @test a isa AbstractString
    @test b isa AbstractString
    @test a != b
    @test strip(a) != strip(b)
    @test strip(lowercase(a)) != strip(lowercase(b))
    @test lowercase(strip(a)) != lowercase(strip(b))
    @test CompatHelper._decode_ssh_private_key(a) == a
    @test CompatHelper._decode_ssh_private_key(b) == a

    c = "-----BEGIN NONSENSE-----\n12345\n-----END NONSENSE-----" # bad
    d = Base64.base64encode(c)
    @test c isa AbstractString
    @test d isa AbstractString
    @test c != d
    @test strip(c) != strip(d)
    @test strip(lowercase(c)) != strip(lowercase(d))
    @test lowercase(strip(c)) != lowercase(strip(d))
    @test_throws ArgumentError CompatHelper._decode_ssh_private_key(c)
    @test_throws CompatHelper.BadSSHPrivateKeyError CompatHelper._decode_ssh_private_key(
        d
    )
end

@testset "utils.jl" begin
    @test CompatHelper.generate_pr_title_parenthetical(:keep, true) ==
               " (keep existing compat)"
    @test CompatHelper.generate_pr_title_parenthetical(:drop, true) ==
               " (drop existing compat)"
    @test CompatHelper.generate_pr_title_parenthetical(:brandnewentry, true) == ""
    @test CompatHelper.generate_pr_title_parenthetical(:keep, false) == ""
    @test CompatHelper.generate_pr_title_parenthetical(:drop, false) == ""
    @test CompatHelper.generate_pr_title_parenthetical(:brandnewentry, false) == ""

    project = Dict{Any,Any}()
    @test !haskey(project, "compat")

    CompatHelper.add_compat_section!(project)
    @test haskey(project, "compat")

    CompatHelper.add_compat_section!(project)
    @test haskey(project, "compat")
end

@testset "version_numbers.jl" begin
    @test CompatHelper.generate_compat_entry(v"1.2.3") == "1.2"
    @test CompatHelper.generate_compat_entry(v"1.2.0") == "1.2"
    @test CompatHelper.generate_compat_entry(v"1.0.3") == "1.0"
    @test CompatHelper.generate_compat_entry(v"1.0.0") == "1.0"
    @test CompatHelper.generate_compat_entry(v"0.2.3") == "0.2"
    @test CompatHelper.generate_compat_entry(v"0.2.0") == "0.2"
    @test CompatHelper.generate_compat_entry(v"0.0.3") == "0.0.3"
    @test CompatHelper.generate_compat_entry(v"0.0.0") == "0.0.0"

    @test CompatHelper._remove_trailing_zeros(v"11.22.33") == "11.22.33"
    @test CompatHelper._remove_trailing_zeros(v"11.22.0") == "11.22"
    @test CompatHelper._remove_trailing_zeros(v"11.0.33") == "11.0.33"
    @test CompatHelper._remove_trailing_zeros(v"11.0.0") == "11"
    @test CompatHelper._remove_trailing_zeros(v"0.22.33") == "0.22.33"
    @test CompatHelper._remove_trailing_zeros(v"0.22.0") == "0.22"
    @test CompatHelper._remove_trailing_zeros(v"0.0.33") == "0.0.33"

    @test_throws DomainError CompatHelper._remove_trailing_zeros(v"0.0.0")
end

@testset "get_latest_version_from_registries.jl" begin
    @testset "_PKG_SERVER_REGISTRY_URL" begin
        CompatHelper._PKG_SERVER_REGISTRY_URL(
            Base.UUID("23338594-aafe-5451-b93e-139f81909106"), nothing
        )
    end

    @testset "_get_registry" begin
        for use_pkg_server in [true, false]
            for JULIA_PKG_SERVER in ["pkg.julialang.org", ""]
                uuid = Base.UUID("23338594-aafe-5451-b93e-139f81909106")
                name = "General"
                url = "https://github.com/JuliaRegistries/General.git"
                registry_urls = nothing
                tmp_dir = mktempdir(; cleanup=true)
                previous_directory = mktempdir(; cleanup=true)

                CompatHelper._get_registry(;
                    use_pkg_server,
                    uuid,
                    registry_urls,
                    tmp_dir,
                    name,
                    previous_directory,
                    url,
                )
            end
        end
    end

    @testset "download_or_clone" begin
        let
            tmp_dir = mktempdir(; cleanup=true)
            previous_directory = mktempdir(; cleanup=true)
            reg_url = "https://example.com/does/not/exists"
            registry_path = joinpath(mktempdir(; cleanup=true), "2")
            url = "https://github.com/JuliaRegistries/General.git"
            name = "General"

            CompatHelper.download_or_clone(
                tmp_dir, previous_directory, reg_url, registry_path, url, name
            )
        end
    end
end
