# Abstract types

abstract type CIService end

# Structs

struct AlwaysAssertionError <: Exception
    msg::String
end

struct BadSSHPrivateKeyError <: Exception
    msg::String
end

struct DefaultBranch
end

struct GitHubActions <: CIService
    username::String
    email::String
end

struct HostnameForClones
    hostname::String
end

struct MajorMinorVersion
    major::Base.VInt
    minor::Base.VInt
end

struct Package
    name::String
    uuid::UUIDs.UUID
end

struct TeamCity <: CIService
    username::String
    email::String
end
