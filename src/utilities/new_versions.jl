body_info(::KeepEntry, name::AbstractString) = "This keeps the compat entries for earlier versions.\n\n"
body_info(::DropEntry, name::AbstractString) = "This drops the compat entries for earlier versions.\n\n"
body_info(::NewEntry, name::AbstractString) = "This is a brand new compat entry. Previously, you did not have a compat entry for the `$(name)` package.\n\n"

title_parenthetical(::KeepEntry) = " (keep existing compat)"
title_parenthetical(::DropEntry) = " (drop existing compat)"
title_parenthetical(::NewEntry) = ""

function new_compat_entry(
    ::KeepEntry,
    old_compat::AbstractString,
    new_compat::AbstractString,
)
    return "$(strip(old_compat)), $(strip(new_compat))"
end

function new_compat_entry(
    ::Union{DropEntry, NewEntry},
    old_compat::AbstractString,
    new_compat::AbstractString,
)
    return "$(strip(new_compat))"
end

function compat_version_number(ver::VersionNumber)
    (ver.major > 0) && return "$(ver.major)"
    (ver.minor > 0) && return "0.$(ver.minor)"

    return "0.0.$(ver.patch)"
end

function subdir_string(subdir::AbstractString)
    if !isempty(subdir)
        subdir_string = " for package $(splitpath(subdir)[end])"
    else
        subdir_string = ""
    end
end

function pr_info(
    version_verbatim::Nothing,
    name::AbstractString,
    compat_entry_for_latest_version::AbstractString,
    compat_entry::AbstractString,
    subdir_string::AbstractString,
    pr_body_keep_or_drop::AbstractString,
    pr_title_parenthetical::AbstractString,
)
    new_pr_title = string(
        "CompatHelper: add new compat entry for ",
        "\"$(name)\" at version ",
        "\"$(compat_entry_for_latest_version)\"",
        "$subdir_string",
        "$(pr_title_parenthetical)"
    )

    new_pr_body = string(
        "This pull request sets the compat ",
        "entry for the `$(name)` package ",
        "to `$(compat_entry)`",
        "$subdir_string.\n\n",
        "$(pr_body_keep_or_drop)",
        "Note: I have not tested your package ",
        "with this new compat entry. ",
        "It is your responsibility to make sure that ",
        "your package tests pass before you merge this ",
        "pull request.\n\n",
        "Note: Consider registering a new release of your package immediately after ",
        "merging this PR, as downstream packages ",
        "may depend on this for tests to pass."
    )

    return (new_pr_title, new_pr_body)
end

function pr_info(
    version_verbatim::AbstractString,
    name::AbstractString,
    compat_entry_for_latest_version::AbstractString,
    compat_entry::AbstractString,
    subdir_string::AbstractString,
    pr_body_keep_or_drop::AbstractString,
    pr_title_parenthetical::AbstractString,
)
    new_pr_title = string(
        "CompatHelper: bump compat for ",
        "\"$(name)\" to ",
        "\"$(compat_entry_for_latest_version)\"",
        "$subdir_string",
        "$(pr_title_parenthetical)"
    )

    new_pr_body = string(
        "This pull request changes the compat ",
        "entry for the `$(name)` package ",
        "from `$(version_verbatim)` ",
        "to `$(compat_entry)`",
        "$subdir_string.\n\n",
        "$(pr_body_keep_or_drop)",
        "Note: I have not tested your package ",
        "with this new compat entry. ",
        "It is your responsibility to make sure that ",
        "your package tests pass before you merge this ",
        "pull request."
    )

    return (new_pr_title, new_pr_body)
end

function skip_equality_specifiers(
    bump_compat_containing_equality_specifier::Bool,
    version_verbatim::Union{AbstractString, Nothing},
)
# To check for an equality specifier (but not an inequality specifier) we look for an equals sign without any
# symbols used for an inequality specifier that would also include an equals sign. Namely, greater than and
# less than. Other specifiers containing symbols like ≥ shouldn't parse as containing an equals sign.
    return !bump_compat_containing_equality_specifier &&
        !isnothing(version_verbatim) &&
        contains(version_verbatim, '=') &&
        !contains(version_verbatim, '>') &&
        !contains(version_verbatim, '<')
end
