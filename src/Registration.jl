__precompile__()

module Registration

    using Common
    using FileManager
    using PyCall

    include("ICP.jl")

    export hello
end # module
