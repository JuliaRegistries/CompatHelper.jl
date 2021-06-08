keep_entry = CompatHelper.KeepEntry()
drop_entry = CompatHelper.DropEntry()
new_entry = CompatHelper.NewEntry()

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
        ],
        drop_entry => [
            (" old ", " new ", "new"),
            ("old", "new", "new"),
            ("Old", "New", "New"),
            ("OLD", "NEW", "NEW"),
        ],
        new_entry => [
            (" old ", " new ", "new"),
            ("old", "new", "new"),
            ("Old", "New", "New"),
            ("OLD", "NEW", "NEW"),
        ],
    )

    entries = collect(keys(cases))

    @testset "$(entry)" for entry in entries
        for case in cases[entry]
            old_compat, new_compat, expected = case
            result = CompatHelper.new_compat_entry(entry, old_compat, new_compat)

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

@testset "subdir_string -- $(subdir)" for (subdir, expected) in [
    ("foobar", "foobar"), ("foo/bar", "bar"), ("1", "1"), ("", "")
]
    if !isempty(subdir)
        @test contains(CompatHelper.subdir_string(subdir), expected)
    else
        @test CompatHelper.subdir_string(subdir) === ""
    end
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
    (nothing, "add new compat entry for", "pull request sets the compat")
    ("", "bump compat for", "pull request changes the compat")
]
    verbatim, expected_title, expected_body = case
    title, body = CompatHelper.pr_info(verbatim, "", "", "", "", "", "")

    @test contains(title, expected_title)
    @test contains(body, expected_body)
end
