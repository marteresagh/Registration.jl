println("loading packages... ")

using ArgParse
using Registration

println("packages OK")

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table! s begin
        "potree"
        help = "Point Cloud to reference"
        arg_type = String
        required = true
        "--ref"
        help = "Reference points"
        arg_type = String
        required = true
        "--picked"
        help = "Picked point cloud points"
        arg_type = String
        required = true
        "--outfolder", "-o"
        help = "Output folder project"
        arg_type = String
        required = true
        "--projname", "-p"
        help = "Project name"
        arg_type = String
        required = true
    end

    return parse_args(s)
end



"""
Save point cloud extracted file .las.
"""

function savepointcloud(potree::String, outputfile::String, ROTO::Matrix)

    # creo l'header
    println("Point cloud: saving ...")

    println("= Compute new AABB...")

    cloudmetadata = FileManager.CloudMetadata(potree)
    tight_aabb = cloudmetadata.tightBoundingBox
    V, _, _ = Common.getmodel(tight_aabb)
    new_V = Common.apply_matrix(ROTO, V)
    aabb = Registration.AABB(new_V)

    trie = FileManager.potree2trie(potree)
    files = FileManager.get_all_values(trie)
    n_points = cloudmetadata.points
    mainHeader = FileManager.newHeader(
        aabb,
        "GeoRef",
        FileManager.SIZE_DATARECORD,
        n_points,
    )

    # apro il las
    t = open(outputfile, "w")
    write(t, Registration.LasIO.magic(Registration.LasIO.format"LAS"))
    write(t, mainHeader)

    println("= Save transformed points...")

    for file in files
        h, laspoints = FileManager.read_LAS_LAZ(file) # read file
        for laspoint in laspoints # read each point
            plas = FileManager.newPointRecord(
                laspoint,
                h,
                Registration.LasIO.LasPoint2,
                mainHeader;
                affineMatrix = ROTO,
            )
            write(t, plas)
        end
    end
    flush(t)
    close(t)

    println("Point cloud: done")
end


function main()
    args = parse_commandline()

    potree = args["potree"]
    picked_ = args["picked"]
    ref_points_ = args["ref"]
    output_folder = args["outfolder"]
    proj_name = args["projname"]


    println("")
    println("== PARAMETERS ==")
    println("Potree  =>  $potree")

    picked = FileManager.load_points(picked_)
    println("Picked points on Potree  =>  $picked")

    ref_points = FileManager.load_points(ref_points_)
    println("Reference points  =>  $ref_points")


    println("Output folder  =>  $output_folder")
    println("Project name  =>  $proj_name")



    println("")
    println("== PROCESSING ==")


    ROTO, fitness, rmse, corr_set =
        Registration.compute_transformation(ref_points, picked)

    io = open(joinpath(output_folder, proj_name * ".rtm"), "w")
    write(io, "$(ROTO[1,1]) $(ROTO[1,2]) $(ROTO[1,3]) $(ROTO[1,4])\n")
    write(io, "$(ROTO[2,1]) $(ROTO[2,2]) $(ROTO[2,3]) $(ROTO[2,4])\n")
    write(io, "$(ROTO[3,1]) $(ROTO[3,2]) $(ROTO[3,3]) $(ROTO[3,4])\n")
    write(io, "$(ROTO[4,1]) $(ROTO[4,2]) $(ROTO[4,3]) $(ROTO[4,4])\n")
    close(io)

    savepointcloud(potree, joinpath(output_folder,proj_name*".las"), ROTO)


    FileManager.successful(
        true,
        output_folder;
        message = "fitness: $fitness\ninlier_rmse: $rmse\ncorrespondence_set: $(size(corr_set,1))"
    )
end

@time main()
