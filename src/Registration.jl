__precompile__()

module Registration

    using Common
    import Common.Points
    using FileManager
    using PyCall

    include("ICP.jl")
    include("IO.jl")

    export Common,FileManager
end # module
