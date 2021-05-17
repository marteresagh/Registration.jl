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
	mainHeader,
	header_bb,
	outputfile,
	n::Int64,
	temp::String,
	)

	Registration.flushprintln("Point cloud: saving ...")

	# update header metadata
	mainHeader.records_count = n # update number of points in header

	#update header bounding box
	Registration.flushprintln("Point cloud: update bbox ...")
	mainHeader.x_min = header_bb.x_min
	mainHeader.y_min = header_bb.y_min
	mainHeader.z_min = header_bb.z_min
	mainHeader.x_max = header_bb.x_max
	mainHeader.y_max = header_bb.y_max
	mainHeader.z_max = header_bb.z_max

	# write las file
	pointtype = Registration.LasIO.pointformat(mainHeader) # las point format

	if n != 0 # if n == 0 nothing to save
		# in temp : list of las point records
		open(temp) do s
			# write las
			open(outputfile,"w") do t
				write(t, Registration.LasIO.magic(Registration.LasIO.format"LAS"))
				write(t,mainHeader)

				Registration.LasIO.skiplasf(s)
				for i = 1:n
					p = read(s, pointtype)
					write(t,p)
				end
			end
		end
	end

	rm(temp) # remove temp
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
	PC_target = FileManager.source2pc(target,lod)
	target_points = FileManager.load_points(picked_target_)
	picked_target = Search.consistent_seeds(PC_target).([c[:] for c in eachcol(target_points)])

	PC_source = FileManager.source2pc(source,lod)
	source_points = FileManager.load_points(picked_source_)
	picked_source = Search.consistent_seeds(PC_source).([c[:] for c in eachcol(source_points)])

	ROTO, fitness, rmse, corr_set = Registration.ICP(PC_target.coordinates,PC_source.coordinates,picked_target,picked_source; threshold = threshold)

	io = open(joinpath(output_folder,proj_name*".txt"),"w")
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
	end

	if isfile(target)
		aabb_original = FileManager.las2aabb(target)
		V,_,_ = Common.getmodel(aabb_original)
		new_V = Common.apply_matrix(ROTO,V)
		aabb_target = Registration.AABB(new_V)
		files_target = [target]
	else
		cloudmetadata = FileManager.CloudMetadata(target)
		aabb_original = cloudmetadata.tightBoundingBox
		V,_,_ = Common.getmodel(aabb_original)
		new_V = Common.apply_matrix(ROTO,V)
		aabb_target = Registration.AABB(new_V)
		trie = FileManager.potree2trie(target)
		files_target = FileManager.get_all_values(trie)
	end

	aabb = Registration.AABB(max(aabb_target.x_max,aabb_source.x_max),min(aabb_target.x_min,aabb_source.x_min),
							 max(aabb_target.y_max,aabb_source.y_max),min(aabb_target.y_min,aabb_source.y_min),
							 max(aabb_target.z_max,aabb_source.z_max),min(aabb_target.z_min,aabb_source.z_min))
	# creo l'header
	header_bb = Registration.AABB(-Inf, Inf,-Inf, Inf,-Inf, Inf)
	mainHeader = FileManager.newHeader(aabb,"REGISTRATION",FileManager.SIZE_DATARECORD)
	# apro il las
	temp = joinpath(output_folder,"temp.las")
	n = 0
	open(temp, "w") do s
		write(s, Registration.LasIO.magic(Registration.LasIO.format"LAS"))
		Registration.flushprintln("Save source points...")
		for file in files_source
			h, laspoints = FileManager.read_LAS_LAZ(file) # read file
			for laspoint in laspoints # read each point
				n = n+1
				point = Common.apply_matrix(ROTO,FileManager.xyz(laspoint,h))
				Common.update_boundingbox!(header_bb,vcat(point...))
				plas = FileManager.newPointRecord(laspoint,h,Registration.LasIO.LasPoint2,mainHeader; affineMatrix = ROTO)
				write(s,plas) # write this record on temporary file
			end
		end
		Registration.flushprintln("Save target points...")
		for file in files_target
			h, laspoints = FileManager.read_LAS_LAZ(file) # read file
			for laspoint in laspoints # read each point
				n = n+1
				point = Common.apply_matrix(ROTO,FileManager.xyz(laspoint,h))
				Common.update_boundingbox!(header_bb,vcat(point...))
				plas = FileManager.newPointRecord(laspoint,h,Registration.LasIO.LasPoint2,mainHeader)
				write(s,plas) # write this record on temporary file
			end
		end
	end

	savepointcloud(
		mainHeader,
		header_bb,
		joinpath(output_folder,proj_name*".las"),
		n::Int64,
		temp::String,
		)

	FileManager.successful(true,output_folder; message = "fitness: $fitness\n inlier_rmse: $rmse\n correspondence_set: $(size(corr_set,1))")
end

@time main()
