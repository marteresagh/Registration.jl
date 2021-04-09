__precompile__()

module Registration

    using Common
    using FileManager
    using PyCall

    const o3d = PyNULL()

    function __init__()
        copy!(o3d, pyimport_conda("open3D"))
    end

    @show o3d.geometry.PointCloud()
    # include("ICP.jl")

    export Common, FileManager
end # module
