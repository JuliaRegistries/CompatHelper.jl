# @inline function MajorMinorVersion(version::VersionNumber)
#     major = version.major::Base.VInt
#     minor = version.minor::Base.VInt
#     result = MajorMinorVersion(major, minor)
#     return result
# end

# @inline MajorMinorVersion(::Nothing) = nothing

# @inline function VersionNumber(x::MajorMinorVersion)
#     major = x.major::Base.VInt
#     minor = x.minor::Base.VInt
#     result = VersionNumber(x, y)::VersionNumber
#     return result
# end

# @inline function Base.isless(a::MajorMinorVersion, b::MajorMinorVersion)
#     a_versionnumber = VersionNumber(a)::VersionNumber
#     b_versionnumber = VersionNumber(b)::VersionNumber
#     result = Base.isless(a_versionnumber, b_versionnumber)
#     return result
# end
