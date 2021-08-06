__precompile__()

module Registration

    using Common
    import Common.Points
    using FileManager
    using PyCall

    include("ICP.jl")
    include("compute_transformation.jl")
    include("downsample.jl")

    export Common,FileManager
end # module
