import UUIDs

abstract type CIService end

struct GitHubActions <: CIService
    username::String
end

struct DefaultBranch
end

struct AlwaysAssertionError <: Exception
    msg::String
end

struct Package
    name::String
    uuid::UUIDs.UUID
end

struct MajorMinorVersion
    major::Base.VInt
    minor::Base.VInt
end
