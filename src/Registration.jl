__precompile__()

module Registration

    using Common
    import Common.Points
    using FileManager
    using PyCall
    using Search

    include("ICP.jl")
    include("compute_transformation.jl")
    include("downsample.jl")

    include("new/struct.jl")
    include("new/main.jl")
    include("new/save.jl")

    export Common,FileManager
end # module
