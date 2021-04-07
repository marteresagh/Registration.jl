__precompile__()

module Registration

    using Common
    using FileManager
    using PyCall

    #include("code.jl")
    # include("2D.jl")
    include("3D.jl")
    export Common,FileManager
end # module
