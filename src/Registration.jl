__precompile__()

module Registration

    # using Common
    # using FileManager
    using PyCall

    const o3d = PyNULL()

    function __init__()
        copy!(o3d, pyimport_conda("open3D.geometry","open3D"))
    end

    function hello()
        @show o3d.PointCloud()
    end
    # include("ICP.jl")

    export hello
end # module
