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
	"--lod"
		help = "Level of detail"
		arg_type = Int
		default = 0
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
	n::Int,
	ROTO::Matrix
	)


	# creo l'header
	Registration.flushprintln("Point cloud: saving ...")
	mainHeader = FileManager.newHeader(aabb,"REGISTRATION",FileManager.SIZE_DATARECORD,n)
	# apro il las
	t = open(outputfile,"w")
		write(t, Registration.LasIO.magic(Registration.LasIO.format"LAS"))
		write(t,mainHeader)
		Registration.flushprintln("Save source points...")
		for file in files_source
			h, laspoints = FileManager.read_LAS_LAZ(file) # read file
			for laspoint in laspoints # read each point
				plas = FileManager.newPointRecord(laspoint,h,Registration.LasIO.LasPoint2,mainHeader; affineMatrix = ROTO)
				write(t,plas) # write this record on temporary file
				flush(t)
			end
		end
		Registration.flushprintln("Save target points...")
		for file in files_target
			h, laspoints = FileManager.read_LAS_LAZ(file) # read file
			for laspoint in laspoints # read each point
				plas = FileManager.newPointRecord(laspoint,h,Registration.LasIO.LasPoint2,mainHeader)
				write(t,plas) # write this record on temporary file
				flush(t)
			end
		end
	close(t)

	Registration.flushprintln("Point cloud: done ...")
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
	lod = args["lod"]

	Registration.flushprintln("")
	Registration.flushprintln("== PARAMETERS ==")
	Registration.flushprintln("Target  =>  $target")
	Registration.flushprintln("Source  =>  $source")
	Registration.flushprintln("Picked points in Target  =>  $picked_target_")
	Registration.flushprintln("Picked points in Source  =>  $picked_source_")
	Registration.flushprintln("Output folder  =>  $output_folder")
	Registration.flushprintln("Project name  =>  $proj_name")
	Registration.flushprintln("Threshold  =>  $threshold")
	Registration.flushprintln("Lod  =>  $lod")

	Registration.flushprintln("")
	Registration.flushprintln("== PROCESSING ==")

	#### AABB dei punti passati MODELS

	target_points = FileManager.load_points(picked_target_)
	source_points = FileManager.load_points(picked_source_)

	aabb_target_points = Common.AABB(target_points)
	aabb_source_points = Common.AABB(source_points)
	aabb_target = Common.getmodel(aabb_target_points)
	aabb_source = Common.getmodel(aabb_source_points)

	M_T = Common.t(Common.centroid(aabb_target[1])...)*Common.s(2.,2.,2.)*Common.t(-Common.centroid(aabb_target[1])...)
	T = Common.apply_matrix(M_T,aabb_target[1])
	M_S = Common.t(Common.centroid(aabb_source[1])...)*Common.s(2.,2.,2.)*Common.t(-Common.centroid(aabb_source[1])...)
	S = Common.apply_matrix(M_S,aabb_source[1])

	aabb_target = (T,aabb_target[2],aabb_target[3])
	aabb_source = (S,aabb_source[2],aabb_source[3])
	#### END AABB MODELs

	file_target = joinpath(output_folder,"target_segment.las")
	file_source = joinpath(output_folder,"source_segment.las")

	OrthographicProjection.segment(target, file_target, aabb_target)
	OrthographicProjection.segment(source, file_source, aabb_source)

	PC_target = FileManager.las2pointcloud(file_target) #FileManager.source2pc(target,lod) # prendo solo i nodi qui interni
	picked_target = Search.consistent_seeds(PC_target).([c[:] for c in eachcol(target_points)])

	PC_source = FileManager.las2pointcloud(file_source) #FileManager.source2pc(source,lod) # prendo solo i nodi qui interni
	picked_source = Search.consistent_seeds(PC_source).([c[:] for c in eachcol(source_points)])

	ROTO, fitness, rmse, corr_set = Registration.ICP(PC_target.coordinates,PC_source.coordinates,picked_target,picked_source; threshold = threshold)

	io = open(joinpath(output_folder,proj_name*".rtm"),"w")
	write(io,"$(ROTO[1,1]) $(ROTO[1,2]) $(ROTO[1,3]) $(ROTO[1,4])\n")
	write(io,"$(ROTO[2,1]) $(ROTO[2,2]) $(ROTO[2,3]) $(ROTO[2,4])\n")
	write(io,"$(ROTO[3,1]) $(ROTO[3,2]) $(ROTO[3,3]) $(ROTO[3,4])\n")
	write(io,"$(ROTO[4,1]) $(ROTO[4,2]) $(ROTO[4,3]) $(ROTO[4,4])\n")
	close(io)


	# save new LAS source
	if isfile(source)
		aabb_original = FileManager.las2aabb(source)
		V,_,_ = Common.getmodel(aabb_original)
		new_V = Common.apply_matrix(ROTO,V)
		aabb_source = Registration.AABB(new_V)
		files_source = [source]
	else
		cloudmetadata = FileManager.CloudMetadata(source)
		aabb_original = cloudmetadata.tightBoundingBox
		V,_,_ = Common.getmodel(aabb_original)
		new_V = Common.apply_matrix(ROTO,V)
		aabb_source = Registration.AABB(new_V)
		trie = FileManager.potree2trie(source)
		files_source = FileManager.get_all_values(trie)
		n_source = cloudmetadata.points
	end

	if isfile(target)
		aabb_target = FileManager.las2aabb(target)
		files_target = [target]
	else
		cloudmetadata = FileManager.CloudMetadata(target)
		aabb_target = cloudmetadata.tightBoundingBox
		trie = FileManager.potree2trie(target)
		files_target = FileManager.get_all_values(trie)
		n_target = cloudmetadata.points
	end

	aabb = Registration.AABB(max(aabb_target.x_max,aabb_source.x_max),min(aabb_target.x_min,aabb_source.x_min),
							 max(aabb_target.y_max,aabb_source.y_max),min(aabb_target.y_min,aabb_source.y_min),
							 max(aabb_target.z_max,aabb_source.z_max),min(aabb_target.z_min,aabb_source.z_min))

	n_points = n_target+n_source
	savepointcloud(files_source,files_target,aabb,joinpath(output_folder,proj_name*".las"),n_points, ROTO)

	FileManager.successful(true,output_folder; message = "fitness: $fitness\ninlier_rmse: $rmse\ncorrespondence_set: $(size(corr_set,1))")
end

@time main()
