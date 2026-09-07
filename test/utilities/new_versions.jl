keep_entry = CompatHelper.KeepEntry()
drop_entry = CompatHelper.DropEntry()
new_entry = CompatHelper.NewEntry()

not_stdlib = CompatHelper.RegularPackage()

hostname = "hostname"
github = GitHubActions(; clone_hostname=hostname)
gitlab = GitLabCI(; clone_hostname=hostname)

@testset "body_info -- $(entry)" for (entry, expected) in [
    (keep_entry, "keeps"), (drop_entry, "drops"), (new_entry, " brand new")
]
    name = "foobar"
    result = CompatHelper.body_info(entry, name)
    @test contains(result, expected)

    if entry isa CompatHelper.NewEntry
        @test contains(result, name)
    end
end

@testset "title_parenthetical -- $(entry)" for (entry, expected) in [
    (keep_entry, "keep"), (drop_entry, "drop"), (new_entry, "")
]
    result = CompatHelper.title_parenthetical(entry)

    if !(entry isa CompatHelper.NewEntry)
        @test contains(result, expected)
    else
        @test isempty(result)
    end
end

@testset "new_compat_entry" begin
    cases = Dict(
        keep_entry => [
            (" old ", " new ", "old, new"),
            ("old", "new", "old, new"),
            ("Old", "New", "Old, New"),
            ("OLD", "NEW", "OLD, NEW"),
            (nothing, "NEW", "NEW"),
        ],
        drop_entry => [
            (" old ", " new ", "new"),
            ("old", "new", "new"),
            ("Old", "New", "New"),
            ("OLD", "NEW", "NEW"),
            (nothing, "NEW", "NEW"),
        ],
        new_entry => [
            (" old ", " new ", "new"),
            ("old", "new", "new"),
            ("Old", "New", "New"),
            ("OLD", "NEW", "NEW"),
            (nothing, "NEW", "NEW"),
        ],
    )

    entries = collect(keys(cases))

    @testset "$(entry)" for entry in entries
        for case in cases[entry]
            old_compat, new_compat, expected = case
            result = CompatHelper.new_compat_entry(
                entry, not_stdlib, old_compat, new_compat
            )

            @test result == expected
        end
    end
end

@testset "compat_version_number -- $(vn)" for (vn, expected) in [
    (VersionNumber("1.0.0"), "1"),
    (VersionNumber("1.1.1"), "1"),
    (VersionNumber("1.1.0"), "1"),
    (VersionNumber("0.1.0"), "0.1"),
    (VersionNumber("0.1.1"), "0.1"),
    (VersionNumber("0.0.1"), "0.0.1"),
    (VersionNumber("0.0.0"), "0.0.0"),
]
    @test CompatHelper.compat_version_number(vn) == expected
end

@testset "append_latest_version -- $(inputs)" for (inputs, expected) in [
    (("1", VersionNumber("1.0.0")), "1"),
    (("1", VersionNumber("2.0.0")), "1, 2"),
    (("1", VersionNumber("1.0.0")), "1"),
    (("1, 2", VersionNumber("2.0.0")), "1, 2"),
    (("1, 2", VersionNumber("3.0.0")), "1, 2, 3"),
]
    (old_compat, ver) = inputs
    observed_output = CompatHelper.append_latest_version(old_compat, ver)
    @test observed_output == expected
end

@testset "subdir_string -- $(subdir)" for (subdir, expected) in [
    ("foobar", "foobar"), ("foo/bar", "bar"), ("1", "1"), ("", "")
]
    if !isempty(subdir)
        @test contains(CompatHelper.subdir_string(subdir), expected)
    else
        @test CompatHelper.subdir_string(subdir) === ""
    end
end

@testset "section_string -- $(section)" for (section, expected) in
                                            [("deps", ""), ("weakdeps", " in [weakdeps]")]
    @test CompatHelper.section_string(section) == expected
end

@testset "skip_equality_specifiers" begin
    cases = [
        (false, "=", true)
        (false, ">=", false)
        (false, "<=", false)
        (false, ">", false)
        (false, "<", false)
    ]

    for case in cases
        bump_specifier, verbatim, expected = case
        @test CompatHelper.skip_equality_specifiers(bump_specifier, verbatim) == expected

        # If bump_compat_containing_equality_specifier is set to true, always return back false
        @test CompatHelper.skip_equality_specifiers(!bump_specifier, verbatim) == false
    end
end

@testset "pr_info -- $(typeof(case[1]))" for case in [
    (nothing, "add new compat entry for", "pull request sets the compat", "deps")
    ("", "bump compat for", "pull request changes the compat", "weakdeps")
]
    verbatim, expected_title, expected_body, section = case
    section_str = section == "deps" ? "" : " in [$section]"
    title, body = CompatHelper.pr_info(verbatim, "", section_str, "", "", "", "", "", "")

    @test contains(title, expected_title)
    section === "weakdeps" && @test contains(title, section_str)
    @test contains(body, expected_body)
end

@testset "create_new_pull_request" begin
    @testset "GitHub" begin
        apply(gh_pr_patch) do
            result, n = CompatHelper.create_new_pull_request(
                GitHub.GitHubAPI(),
                GitHub.Repo(; owner=GitHub.User(; login="username"), name="repo"),
                "new_branch",
                "master_branch",
                "title",
                "body",
            )

            @test isnothing(n)
            @test result isa GitHub.PullRequest
        end
    end

    @testset "GitLab" begin
        apply(gl_pr_patch) do
            result, n = CompatHelper.create_new_pull_request(
                GitLab.GitLabAPI(),
                GitLab.Project(; id=1),
                "new_branch",
                "master_brach",
                "title",
                "body",
            )

            @test isnothing(n)
            @test result isa GitLab.MergeRequest
        end
    end
end

@testset "get_url_with_auth" begin
    @testset "GitHub" begin
        result = CompatHelper.get_url_with_auth(
            GitHub.GitHubAPI(; token=GitHub.Token("token")),
            github,
            GitHub.Repo(; full_name="full_name"),
        )

        @test result == "https://x-access-token:token@hostname/full_name.git"
    end

    @testset "GitLab" begin
        result = CompatHelper.get_url_with_auth(
            GitLab.GitLabAPI(; token=GitLab.OAuth2Token("token")),
            gitlab,
            GitLab.Project(; path_with_namespace="full_name"),
        )

        @test result == "https://oauth2:token@hostname/full_name.git"
    end
end

@testset "get_url_for_ssh" begin
    @testset "GitHub" begin
        result = CompatHelper.get_url_for_ssh(
            GitHub.GitHubAPI(), github, GitHub.Repo(; full_name="full_name")
        )

        @test result == "git@hostname:full_name.git"
    end

    @testset "GitLab" begin
        result = CompatHelper.get_url_for_ssh(
            GitLab.GitLabAPI(), gitlab, GitLab.Project(; path_with_namespace="full_name")
        )

        @test result == "git@hostname:full_name.git"
    end
end

@testset "continue_with_pr" begin
    @testset "default passing case" begin
        pass_dep = CompatHelper.DepInfo(
            CompatHelper.Package("PackageA", UUID(1)); latest_version=VersionNumber(1)
        )
        @test CompatHelper.continue_with_pr(pass_dep, false)
        @test CompatHelper.continue_with_pr(pass_dep, true)
    end

    @testset "latest version in version spec" begin
        dep = CompatHelper.DepInfo(
            CompatHelper.Package("PackageA", UUID(1));
            latest_version=VersionNumber(1),
            version_spec=CompatHelper.VersionSpec(["0.9", "1.0"]),
        )
        @test !CompatHelper.continue_with_pr(dep, false)
        @test !CompatHelper.continue_with_pr(dep, true)
    end

    @testset "equality specifier" begin
        dep = CompatHelper.DepInfo(
            CompatHelper.Package("PackageA", UUID(1));
            version_verbatim="= 1.2",
            latest_version=VersionNumber(2),
        )
        @test !CompatHelper.continue_with_pr(dep, false)
        @test CompatHelper.continue_with_pr(dep, true)
    end

    @testset "no latest version" begin
        dep = CompatHelper.DepInfo(CompatHelper.Package("PackageA", UUID(1)))
        @test !CompatHelper.continue_with_pr(dep, false)
        @test !CompatHelper.continue_with_pr(dep, true)
    end
end

@testset "create_ssh_private_key" begin
    mktempdir() do tmpdir
        withenv(CompatHelper.PRIVATE_SSH_ENVVAR => "foo") do
            pkey = apply(decode_pkey_patch) do
                CompatHelper.create_ssh_private_key(tmpdir)
            end

            @test isfile(pkey)
            open(pkey, "r") do io
                @test read(io, String) == "pkey_info\n"
            end
        end
    end
end

@testset "force_ci_trigger" begin
    @testset "GitLab" begin
        mktempdir() do f
            cd(f) do
                run(`git init`)

                run(`touch foobar.txt`)
                CompatHelper.git_add()
                @test CompatHelper.git_commit("Message")

                run(`touch bazbar.txt`)
                CompatHelper.git_add()
                @test CompatHelper.git_commit("Message2")

                hash = read(`git rev-parse HEAD`, String)

                CompatHelper.force_ci_trigger(GitLab.GitLabAPI(), "title", "master", "pkey")
                new_hash = read(`git rev-parse HEAD`, String)
                @test hash == new_hash
            end
        end
    end

    @testset "GitHub" begin
        @testset "with pkey" begin
            mktempdir() do f
                cd(f) do
                    run(`git init`)

                    run(`touch foobar.txt`)
                    CompatHelper.git_add()
                    @test CompatHelper.git_commit("Message")

                    run(`touch bazbar.txt`)
                    CompatHelper.git_add()
                    @test CompatHelper.git_commit("Message2")

                    hash = read(`git rev-parse HEAD`, String)

                    apply(git_push_patch) do
                        CompatHelper.force_ci_trigger(
                            GitHub.GitHubAPI(), "title", "master", "pkey"
                        )
                    end
                    new_hash = read(`git rev-parse HEAD`, String)
                    @test hash != new_hash
                end
            end
        end

        @testset "without pkey" begin
            mktempdir() do f
                cd(f) do
                    run(`git init`)

                    run(`touch foobar.txt`)
                    CompatHelper.git_add()
                    @test CompatHelper.git_commit("Message")

                    run(`touch bazbar.txt`)
                    CompatHelper.git_add()
                    @test CompatHelper.git_commit("Message2")

                    hash = read(`git rev-parse HEAD`, String)

                    apply(git_push_patch) do
                        CompatHelper.force_ci_trigger(
                            GitHub.GitHubAPI(), "title", "master", nothing
                        )
                    end
                    new_hash = read(`git rev-parse HEAD`, String)
                    @test hash == new_hash
                end
            end
        end
    end
end

@testset "modify_project_toml" begin
    mktempdir() do tmpdir
        # Lets copy our test Project.toml to the tmpdir for this test
        src = joinpath(@__DIR__, "..", "deps", "Project.toml")
        dst = joinpath(tmpdir, "Project.toml")
        cp(src, dst; force=true)

        project = TOML.parsefile(dst)
        @test !haskey(project["compat"], "PackageA")

        CompatHelper.modify_project_toml("PackageA", tmpdir, "= 1.2", false)

        project = TOML.parsefile(dst)
        @test project["compat"]["PackageA"] == "= 1.2"
    end
end

@testset "bump_package_version" begin
    @testset "minor bump" begin
        mock_toml = Dict("version" => "1.4.5")

        @test mock_toml["version"] == "1.4.5"
        CompatHelper.bump_package_version!(mock_toml)
        @test mock_toml["version"] == "1.5.0"
    end

    @testset "patch bump" begin
        mock_toml = Dict("version" => "0.5.2")

        @test mock_toml["version"] == "0.5.2"
        CompatHelper.bump_package_version!(mock_toml)
        @test mock_toml["version"] == "0.5.3"
    end

    @testset "dev prerelease" begin
        mock_toml = Dict("version" => "1.2.3-DEV")

        @test mock_toml["version"] == "1.2.3-DEV"
        CompatHelper.bump_package_version!(mock_toml)
        @test mock_toml["version"] == "1.2.3-DEV"
    end

    @testset "version undefined" begin
        mock_toml = Dict()
        CompatHelper.bump_package_version!(mock_toml)
        @test isempty(mock_toml)
    end
end

@testset "cc_mention_user" begin
    @testset "GitHub" begin
        apply(gh_comment_patch) do
            withenv("GITHUB_ACTOR" => "username") do
                result, n = CompatHelper.cc_mention_user(
                    GitHub.GitHubAPI(),
                    GitHub.Repo(; owner=GitHub.User(; login="username"), name="repo"),
                    GitHub.PullRequest(; id=1),
                )

                @test isnothing(n)
                @test result isa GitHub.Comment
            end
        end
    end

    @testset "GitLab" begin
        apply(gl_comment_patch) do
            withenv("GITLAB_USER_LOGIN" => "username") do
                result, n = CompatHelper.cc_mention_user(
                    GitLab.GitLabAPI(), GitLab.Project(; id=1), GitLab.MergeRequest(; iid=1)
                )

                @test isnothing(n)
                @test result isa GitLab.Note
            end
        end
    end
end

@testset "unsub_from_pr" begin
    @testset "GitHub" begin
        api = GitHub.GitHubAPI()
        @test_throws GitForge.ForgeAPINotImplemented(
            GitForge.unsubscribe_from_pull_request, (1, 1), true, api
        ) CompatHelper.unsub_from_pr(
            api, GitHub.PullRequest(; repo=GitHub.Repo(; id=1), id=1)
        )
    end

    @testset "GitLab" begin
        apply(gl_unsub_patch) do
            result, n = CompatHelper.unsub_from_pr(
                GitLab.GitLabAPI(), GitLab.MergeRequest(; project_id=1, iid=1)
            )

            @test isnothing(n)
            @test result isa GitLab.MergeRequest
        end
    end
end

@testset "make_pr_for_new_version" begin
    @testset "latest_version === nothing" begin
        options = CompatHelper.Options()
        subdir = only(options.subdirs)
        @test isnothing(
            CompatHelper.make_pr_for_new_version(
                GitHub.GitHubAPI(),
                GitHub.Repo(),
                CompatHelper.DepInfo(CompatHelper.Package("PackageA", UUID(1))),
                CompatHelper.KeepEntry(),
                CompatHelper.GitHubActions();
                options,
                subdir,
                local_clone_path=mktempdir(),
                dep_section="deps",
            ),
        )
    end

    @testset "pr_title exists" begin
        apply(pr_titles_mock) do
            options = CompatHelper.Options()
            subdir = only(options.subdirs)
            @test isnothing(
                CompatHelper.make_pr_for_new_version(
                    GitHub.GitHubAPI(; token=GitHub.Token("token")),
                    GitHub.Repo(),
                    CompatHelper.DepInfo(
                        CompatHelper.Package("PackageA", UUID(1));
                        latest_version=VersionNumber(1),
                        version_verbatim="0.9",
                    ),
                    CompatHelper.KeepEntry(),
                    CompatHelper.GitHubActions();
                    options,
                    subdir,
                    local_clone_path=mktempdir(),
                    dep_section="deps",
                ),
            )
        end
    end

    @testset "Successful Run" begin
        mktempdir() do tmpdir
            # Create a temp git repo
            cd(tmpdir) do
                run(`git init`)

                # Lets copy our test Project.toml to the tmpdir for this test
                src = joinpath(@__DIR__, "..", "deps", "Project.toml")
                dst = joinpath(tmpdir, "Project.toml")
                cp(src, dst; force=true)

                CompatHelper.git_add()
                CompatHelper.git_commit("msg")
            end

            cd(@__DIR__) do
                patches = [
                    pr_titles_mock,
                    git_push_patch,
                    gh_pr_patch,
                    make_clone_https_patch(tmpdir),
                    make_clone_ssh_patch(tmpdir),
                    decode_pkey_patch,
                ]

                apply(patches) do
                    # HTTPS
                    # Make sure PRIVATE_SSH_ENVVAR is unset
                    if haskey(ENV, CompatHelper.PRIVATE_SSH_ENVVAR)
                        delete!(ENV, CompatHelper.PRIVATE_SSH_ENVVAR)
                    end

                    options = CompatHelper.Options()
                    subdir = only(options.subdirs)
                    pr = CompatHelper.make_pr_for_new_version(
                        GitHub.GitHubAPI(; token=GitHub.Token("token")),
                        GitHub.Repo(;
                            owner=GitHub.User(; login="username"), name="PackageB"
                        ),
                        CompatHelper.DepInfo(
                            CompatHelper.Package("PackageB", UUID(1));
                            latest_version=VersionNumber(2),
                            version_verbatim="1.2",
                        ),
                        CompatHelper.KeepEntry(),
                        CompatHelper.GitHubActions();
                        options,
                        subdir,
                        local_clone_path=tmpdir,
                        dep_section="deps",
                    )
                    @test pr isa GitHub.PullRequest

                    # SSH
                    withenv(CompatHelper.PRIVATE_SSH_ENVVAR => "foo") do
                        options = CompatHelper.Options()
                        subdir = only(options.subdirs)
                        pr = CompatHelper.make_pr_for_new_version(
                            GitHub.GitHubAPI(; token=GitHub.Token("token")),
                            GitHub.Repo(;
                                owner=GitHub.User(; login="username"), name="PackageC"
                            ),
                            CompatHelper.DepInfo(
                                CompatHelper.Package("PackageC", UUID(1));
                                latest_version=VersionNumber(3),
                                version_verbatim="2.1",
                            ),
                            CompatHelper.KeepEntry(),
                            CompatHelper.GitHubActions();
                            options,
                            subdir,
                            local_clone_path=tmpdir,
                            dep_section="deps",
                        )
                        @test pr isa GitHub.PullRequest
                    end
                end
            end
        end
    end
end
