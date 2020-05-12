import Base64

Test.@testset "assert.jl" begin
    Test.@test_nowarn CompatHelper.always_assert(true)
    Test.@test CompatHelper.always_assert(true) isa Nothing
    Test.@test CompatHelper.always_assert(true) == nothing
    Test.@test Test.@test_nowarn CompatHelper.always_assert(true) isa Nothing
    Test.@test Test.@test_nowarn CompatHelper.always_assert(true) == nothing
    Test.@test_throws CompatHelper.AlwaysAssertionError CompatHelper.always_assert(false)
end

Test.@testset "ci_service.jl" begin
    withenv("GITHUB_REPOSITORY" => "foo/bar") do
        Test.@test CompatHelper.auto_detect_ci_service() isa CompatHelper.CIService
        Test.@test CompatHelper.auto_detect_ci_service() isa CompatHelper.GitHubActions
        Test.@test_throws ArgumentError CompatHelper.main(; keep_existing_compat = false, drop_existing_compat = false)
    end
    withenv("GITHUB_REPOSITORY" => nothing) do
        Test.@test_throws ErrorException CompatHelper.auto_detect_ci_service()
    end
end

Test.@testset "git.jl" begin
    Test.@test CompatHelper.git_decide_master_branch(CompatHelper.DefaultBranch(), "  abcdefg  ") == "abcdefg"
    Test.@test CompatHelper.git_decide_master_branch(" abc ", " xyz ") == "abc"
end

Test.@testset "new_versions.jl" begin
    Test.@test_throws ArgumentError CompatHelper.old_compat_to_new_compat("", "", :abc)
end

Test.@testset "pull_requests.jl" begin
    a = GitHub.Repo(Dict("name" => "Foo", "full_name" => "Foo", "owner" => "Foo", "id" => 1, "url" => "Foo", "html_url" => "Foo", "fork" => false))
    b = GitHub.Repo(Dict("name" => "Foo", "full_name" => "Foo", "owner" => "Foo", "id" => 1, "url" => "Foo", "html_url" => "Foo", "fork" => false))
    c = GitHub.Repo(Dict("name" => "Foo", "full_name" => "Foo", "owner" => "Foo", "id" => 1, "url" => "Foo", "html_url" => "Foo", "fork" => true))
    Test.@test !CompatHelper._repos_are_the_same(a, nothing)
    Test.@test !CompatHelper._repos_are_the_same(nothing, a)
    Test.@test !CompatHelper._repos_are_the_same(nothing, nothing)
    Test.@test CompatHelper._repos_are_the_same(a, a)
    Test.@test CompatHelper._repos_are_the_same(a, b)
    Test.@test !CompatHelper._repos_are_the_same(a, c)
    Test.@test CompatHelper._repos_are_the_same(b, a)
    Test.@test CompatHelper._repos_are_the_same(b, b)
    Test.@test !CompatHelper._repos_are_the_same(b, c)
    Test.@test !CompatHelper._repos_are_the_same(c, a)
    Test.@test !CompatHelper._repos_are_the_same(c, b)
    Test.@test CompatHelper._repos_are_the_same(c, c)
end

Test.@testset "ssh_keys.jl" begin
    a = "-----BEGIN OPENSSH PRIVATE KEY-----\n12345\n-----END OPENSSH PRIVATE KEY-----" # good
    b = Base64.base64encode(a)
    Test.@test a isa AbstractString
    Test.@test b isa AbstractString
    Test.@test a != b
    Test.@test strip(a) != strip(b)
    Test.@test strip(lowercase(a)) != strip(lowercase(b))
    Test.@test lowercase(strip(a)) != lowercase(strip(b))
    Test.@test CompatHelper._decode_ssh_private_key(a) == a
    Test.@test CompatHelper._decode_ssh_private_key(b) == a

    c = "-----BEGIN NONSENSE-----\n12345\n-----END NONSENSE-----" # bad
    d = Base64.base64encode(c)
    Test.@test c isa AbstractString
    Test.@test d isa AbstractString
    Test.@test c != d
    Test.@test strip(c) != strip(d)
    Test.@test strip(lowercase(c)) != strip(lowercase(d))
    Test.@test lowercase(strip(c)) != lowercase(strip(d))
    Test.@test_throws ArgumentError CompatHelper._decode_ssh_private_key(c)
    Test.@test_throws CompatHelper.BadSSHPrivateKeyError CompatHelper._decode_ssh_private_key(d)
end

Test.@testset "utils.jl" begin
    Test.@test CompatHelper.generate_pr_title_parenthetical(:keep, true) == " (keep existing compat)"
    Test.@test CompatHelper.generate_pr_title_parenthetical(:drop, true) == " (drop existing compat)"
    Test.@test CompatHelper.generate_pr_title_parenthetical(:brandnewentry, true) == ""
    Test.@test CompatHelper.generate_pr_title_parenthetical(:keep, false) == ""
    Test.@test CompatHelper.generate_pr_title_parenthetical(:drop, false) == ""
    Test.@test CompatHelper.generate_pr_title_parenthetical(:brandnewentry, false) == ""
    project = Dict{Any, Any}()
    Test.@test !haskey(project, "compat")
    CompatHelper.add_compat_section!(project)
    Test.@test haskey(project, "compat")
    CompatHelper.add_compat_section!(project)
    Test.@test haskey(project, "compat")
end

Test.@testset "version_numbers.jl" begin
    Test.@test CompatHelper.generate_compat_entry(v"1.2.3") == "1.2"
    Test.@test CompatHelper.generate_compat_entry(v"1.2.0") == "1.2"
    Test.@test CompatHelper.generate_compat_entry(v"1.0.3") == "1.0"
    Test.@test CompatHelper.generate_compat_entry(v"1.0.0") == "1.0"
    Test.@test CompatHelper.generate_compat_entry(v"0.2.3") == "0.2"
    Test.@test CompatHelper.generate_compat_entry(v"0.2.0") == "0.2"
    Test.@test CompatHelper.generate_compat_entry(v"0.0.3") == "0.0.3"
    Test.@test CompatHelper.generate_compat_entry(v"0.0.0") == "0.0.0"

    Test.@test CompatHelper._remove_trailing_zeros(v"11.22.33") == "11.22.33"
    Test.@test CompatHelper._remove_trailing_zeros(v"11.22.0") == "11.22"
    Test.@test CompatHelper._remove_trailing_zeros(v"11.0.33") == "11.0.33"
    Test.@test CompatHelper._remove_trailing_zeros(v"11.0.0") == "11"
    Test.@test CompatHelper._remove_trailing_zeros(v"0.22.33") == "0.22.33"
    Test.@test CompatHelper._remove_trailing_zeros(v"0.22.0") == "0.22"
    Test.@test CompatHelper._remove_trailing_zeros(v"0.0.33") == "0.0.33"
    Test.@test_throws DomainError CompatHelper._remove_trailing_zeros(v"0.0.0")
end
