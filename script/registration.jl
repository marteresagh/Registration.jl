# TODO SOLO PER POTREE

println("loading packages... ")

using ArgParse
using Registration
using Search
using OrthographicProjection

println("packages OK")


function parse_commandline()
	s = ArgParseSettings()

	@add_arg_table! s begin
	"target"
		help = "Target points"
		arg_type = String
		required = true
	"source"
		help = "Source points"
		arg_type = String
		required = true
	"--picked_target", "-t"
		help = "Picked target points"
		arg_type = String
		required = true
	"--picked_source", "-s"
		help = "Picked source points"
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
	"--threshold"
		help = "Distance threshold"
		arg_type = Float64
		default = 0.03
	"--scale"
		help = "Scale factor of BB"
		arg_type = Float64
		default = 1.3
	"--it"
		help = "Scale factor of BB"
		arg_type = Int64
		default = 1000
	"--size"
		help = "size voxel"
		arg_type = Float64
		default = 0.001
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

# function segment_las(file_las::String, outputfile::String, box::Common.LAR)
# 	t = open(outputfile,"w")
# 	h, laspoints = FileManager.read_LAS_LAZ(file_las) # read file
# 	for laspoint in laspoints # read each point
# 		plas = FileManager.newPointRecord(laspoint,h,Registration.LasIO.LasPoint2,mainHeader)
# 		write(t,plas) # write this record on temporary file
# 		flush(t)
# 	end
# end

function get_BB(points::Common.Points, s = 1.3::Float64)

	aabb_original = Common.AABB(points)
	C = ([aabb_original.x_min,aabb_original.y_min,aabb_original.z_min]+[aabb_original.x_max,aabb_original.y_max,aabb_original.z_max])/2

	aabb_model = Common.getmodel(aabb_original)

	M = Common.t(C...)*Common.s(s,s,s)*Common.t(-C...)
	V = Common.apply_matrix(M,aabb_model[1])

	aabb_scaled = (V, aabb_model[2], aabb_model[3])
	return aabb_scaled
end

function main()
	args = parse_commandline()

	target = args["target"]
	source = args["source"]
	picked_target_ = args["picked_target"]
	picked_source_ = args["picked_source"]
	output_folder = args["outfolder"]
	proj_name = args["projname"]
	threshold = args["threshold"]
	scale = args["scale"]
	max_it = args["it"]
	size_voxel = args["size"]

	Registration.flushprintln("")
	Registration.flushprintln("== PARAMETERS ==")
	Registration.flushprintln("Target  =>  $target")
	Registration.flushprintln("Source  =>  $source")
	Registration.flushprintln("Picked points in Target  =>  $picked_target_")
	Registration.flushprintln("Picked points in Source  =>  $picked_source_")
	Registration.flushprintln("Output folder  =>  $output_folder")
	Registration.flushprintln("Project name  =>  $proj_name")
	Registration.flushprintln("Threshold  =>  $threshold")
	Registration.flushprintln("Scale  =>  $scale")
	Registration.flushprintln("Max iteration  =>  $max_it")
	Registration.flushprintln("Size voxel  =>  $size_voxel")

	Registration.flushprintln("")
	Registration.flushprintln("== SEGMENT ==")

	file_target = joinpath(output_folder,"target_segment.las")
	file_source = joinpath(output_folder,"source_segment.las")

	# if isfile(source) && isfile(target)
	# 	segment_las(target, file_target, aabb_target)
	# 	segment_las(source, file_source, aabb_source)
	# else
	PC_target = nothing
	PC_source = nothing
	picked_target = nothing
	picked_source = nothing

	task1 = Threads.@spawn begin
		target_points = FileManager.load_points(picked_target_)
		aabb_target = get_BB(target_points, scale)
		OrthographicProjection.segment(target, file_target, aabb_target; temp_name = "temp_target.las")
		PC_target = FileManager.las2pointcloud(file_target)
		picked_target = Search.consistent_seeds(PC_target).([c[:] for c in eachcol(target_points)])
	end

	task2 = Threads.@spawn begin
		source_points = FileManager.load_points(picked_source_)
		aabb_source = get_BB(source_points, scale)
		OrthographicProjection.segment(source, file_source, aabb_source; temp_name = "temp_source.las")
		PC_source = FileManager.las2pointcloud(file_source)
		picked_source = Search.consistent_seeds(PC_source).([c[:] for c in eachcol(source_points)])
	end

	fetch(task1)
	fetch(task2)

	Registration.flushprintln("")
	Registration.flushprintln("== PROCESSING ==")


	ROTO, fitness, rmse, corr_set = Registration.ICP(PC_target.coordinates,PC_source.coordinates,picked_target,picked_source; threshold = threshold, max_it = max_it)

	io = open(joinpath(output_folder,proj_name*".rtm"),"w")
	write(io,"$(ROTO[1,1]) $(ROTO[1,2]) $(ROTO[1,3]) $(ROTO[1,4])\n")
	write(io,"$(ROTO[2,1]) $(ROTO[2,2]) $(ROTO[2,3]) $(ROTO[2,4])\n")
	write(io,"$(ROTO[3,1]) $(ROTO[3,2]) $(ROTO[3,3]) $(ROTO[3,4])\n")
	write(io,"$(ROTO[4,1]) $(ROTO[4,2]) $(ROTO[4,3]) $(ROTO[4,4])\n")
	close(io)

	# PC = PointCloud(hcat(PC_target.coordinates,Common.apply_matrix(ROTO,PC_source.coordinates)),hcat(PC_target.rgbs,PC_source.rgbs))
	# OUT = Registration.down_sample(PC,0.001)

	cloud_S = FileManager.CloudMetadata(source)
	aabb_original = cloud_S.tightBoundingBox
	V,_,_ = Common.getmodel(aabb_original)
	new_V = Common.apply_matrix(ROTO,V)
	aabb_source = Registration.AABB(new_V)
	trie = FileManager.potree2trie(source)
	files_source = FileManager.get_all_values(trie)
	n_source = cloud_S.points

	cloud_T = FileManager.CloudMetadata(target)
	aabb_target = cloud_T.tightBoundingBox
	trie = FileManager.potree2trie(target)
	files_target = FileManager.get_all_values(trie)
	n_target = cloud_T.points


	aabb = Registration.AABB(max(aabb_target.x_max,aabb_source.x_max),min(aabb_target.x_min,aabb_source.x_min),
							 max(aabb_target.y_max,aabb_source.y_max),min(aabb_target.y_min,aabb_source.y_min),
							 max(aabb_target.z_max,aabb_source.z_max),min(aabb_target.z_min,aabb_source.z_min))


	savepointcloud(files_source, files_target, aabb, joinpath(output_folder,proj_name*".las"), ROTO, size_voxel)
	# n_points = n_target+n_source
	# savepointcloud(files_source, files_target, aabb, joinpath(output_folder,proj_name*".las"), n_points, ROTO)

	FileManager.successful(true,output_folder; message = "fitness: $fitness\ninlier_rmse: $rmse\ncorrespondence_set: $(size(corr_set,1))")
end

@time main()
