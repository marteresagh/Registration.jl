# TODO SOLO PER POTREE

println("loading packages... ")

using ArgParse
using Registration
using Search

println("packages OK")

function parse_commandline()
	s = ArgParseSettings()

	@add_arg_table! s begin
	"target"
		help = "Target points"
		arg_type = String
		required = true
	"picked_ref"
		help = "Ref points"
		arg_type = String
		required = true
	"--picked_target", "-t"
		help = "Picked target points"
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
function savepointcloud(
	files_source::Vector{String},
	files_target::Vector{String},
	aabb::Common.AABB,
	outputfile::String,
	ROTO::Matrix,
	size_voxel
	)

	# creo l'header
	Registration.flushprintln("Point cloud: decimation ...")
	PC_source = FileManager.las2pointcloud(files_source...)
	PC_target = FileManager.las2pointcloud(files_target...)
	PC_registered = Common.PointCloud(hcat(PC_target.coordinates,Common.apply_matrix(ROTO,PC_source.coordinates)),hcat(PC_target.rgbs,PC_source.rgbs))
	PC_decimated = Registration.down_sample(PC_registered,size_voxel)
	Registration.flushprintln("num points: $(PC_registered.n_points) -> $(PC_decimated.n_points)")
	Registration.flushprintln("Point cloud: saving ...")
	mainHeader = FileManager.newHeader(aabb,"REGISTRATION",FileManager.SIZE_DATARECORD,PC_decimated.n_points)

	open(outputfile,"w") do t
		write(t, FileManager.LasIO.magic(FileManager.LasIO.format"LAS"))
		write(t, mainHeader)

		for i in 1:PC_decimated.n_points
			p = FileManager.newPointRecord(PC_decimated.coordinates[:,i], convert.(FileManager.LasIO.N0f16,PC_decimated.rgbs[:,i]) , FileManager.LasIO.LasPoint2, mainHeader)
			write(t,p)
		end
	end

	Registration.flushprintln("Point cloud: done ...")
end

#
# function savepointcloud(
# 	files_source::Vector{String},
# 	files_target::Vector{String},
# 	aabb::Common.AABB,
# 	outputfile::String,
# 	n::Int,
# 	ROTO::Matrix
# 	)
#
# 	# creo l'header
# 	Registration.flushprintln("Point cloud: saving ...")
# 	mainHeader = FileManager.newHeader(aabb,"REGISTRATION",FileManager.SIZE_DATARECORD,n)
# 	# apro il las
# 	t = open(outputfile,"w")
# 		write(t, Registration.LasIO.magic(Registration.LasIO.format"LAS"))
# 		write(t,mainHeader)
# 		Registration.flushprintln("Save source points...")
# 		for file in files_source
# 			h, laspoints = FileManager.read_LAS_LAZ(file) # read file
# 			for laspoint in laspoints # read each point
# 				plas = FileManager.newPointRecord(laspoint,h,Registration.LasIO.LasPoint2,mainHeader; affineMatrix = ROTO)
# 				write(t,plas)
# 				flush(t)
# 			end
# 		end
# 		Registration.flushprintln("Save target points...")
# 		for file in files_target
# 			h, laspoints = FileManager.read_LAS_LAZ(file) # read file
# 			for laspoint in laspoints # read each point
# 				plas = FileManager.newPointRecord(laspoint,h,Registration.LasIO.LasPoint2,mainHeader)
# 				write(t,plas)
# 				flush(t)
# 			end
# 		end
# 	close(t)
#
# 	Registration.flushprintln("Point cloud: done ...")
# end


function main()
	args = parse_commandline()

	target = args["target"]
	picked_ref_ = args["picked_ref"]
	picked_target_ = args["picked_target"]
	output_folder = args["outfolder"]
	proj_name = args["projname"]


	Registration.flushprintln("")
	Registration.flushprintln("== PARAMETERS ==")
	Registration.flushprintln("Target  =>  $target")

	picked_ref = FileManager.load_points(picked_ref_)
	Registration.flushprintln("Ref Points  =>  $picked_ref")

	picked_target = FileManager.load_points(picked_target_)
	Registration.flushprintln("Picked points in Target  =>  $picked_target")


	Registration.flushprintln("Output folder  =>  $output_folder")
	Registration.flushprintln("Project name  =>  $proj_name")



	Registration.flushprintln("")
	Registration.flushprintln("== PROCESSING ==")


	ROTO, fitness, rmse, corr_set = Registration.ICP(PC_target.coordinates,PC_source.coordinates,picked_target,picked_source; threshold = threshold, max_it = max_it)

	io = open(joinpath(output_folder,proj_name*".rtm"),"w")
	write(io,"$(ROTO[1,1]) $(ROTO[1,2]) $(ROTO[1,3]) $(ROTO[1,4])\n")
	write(io,"$(ROTO[2,1]) $(ROTO[2,2]) $(ROTO[2,3]) $(ROTO[2,4])\n")
	write(io,"$(ROTO[3,1]) $(ROTO[3,2]) $(ROTO[3,3]) $(ROTO[3,4])\n")
	write(io,"$(ROTO[4,1]) $(ROTO[4,2]) $(ROTO[4,3]) $(ROTO[4,4])\n")
	close(io)


	savepointcloud(files_source, files_target, aabb, joinpath(output_folder,proj_name*".las"), ROTO, size_voxel)
	# n_points = n_target+n_source
	# savepointcloud(files_source, files_target, aabb, joinpath(output_folder,proj_name*".las"), n_points, ROTO)

	FileManager.successful(true,output_folder; message = "fitness: $fitness\ninlier_rmse: $rmse\ncorrespondence_set: $(size(corr_set,1))")
end

@time main()
