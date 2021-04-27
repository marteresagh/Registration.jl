__precompile__()

module Registration

    using Common
    import Common.Points
    using FileManager
    using PyCall

    include("ICP.jl")

    export Common,FileManager
end # module
