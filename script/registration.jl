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
		required = true
	"source"
		help = "Source points"
		required = true
	"--picked_target", "-t"
		help = "Picked target points"
		required = true
	"--picked_source", "-s"
		help = "Picked source points"
		required = true
	"--output", "-o"
		help = "Output filename (.txt)"
		required = true
	"--threshold"
		help = "Distance threshold"
		default = 0.03
	"--lod"
		help = "Level of detail"
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

	flushprintln("Point cloud: saving ...")

	# update header metadata
	mainHeader.records_count = n # update number of points in header

	#update header bounding box
	flushprintln("Point cloud: update bbox ...")
	mainHeader.x_min = header_bb.x_min
	mainHeader.y_min = header_bb.y_min
	mainHeader.z_min = header_bb.z_min
	mainHeader.x_max = header_bb.x_max
	mainHeader.y_max = header_bb.y_max
	mainHeader.z_max = header_bb.z_max

	# write las file
	pointtype = LasIO.pointformat(mainHeader) # las point format

	if n != 0 # if n == 0 nothing to save
		# in temp : list of las point records
		open(temp) do s
			# write las
			open(outputfile,"w") do t
				write(t, LasIO.magic(LasIO.format"LAS"))
				write(t,mainHeader)

				LasIO.skiplasf(s)
				for i = 1:n
					p = read(s, pointtype)
					write(t,p)
				end
			end
		end
	end

	rm(temp) # remove temp
	flushprintln("Point cloud: done ...")
end


function main()
	args = parse_commandline()

	target = args["target"]
	source = args["source"]
	picked_target_ = args["picked_target"]
	picked_source_ = args["picked_source"]
	output_file = args["output"]
	threshold = args["threshold"]
	lod = args["lod"]

	Registration.flushprintln("")
	Registration.flushprintln("== PARAMETERS ==")
	Registration.flushprintln("Target  =>  $target")
	Registration.flushprintln("Source  =>  $source")
	Registration.flushprintln("Picked points in Target  =>  $picked_target_")
	Registration.flushprintln("Picked points in Source  =>  $picked_source_")
	Registration.flushprintln("Output file  =>  $output_file")
	Registration.flushprintln("Threshold  =>  $threshold")

	Registration.flushprintln("")
	Registration.flushprintln("== PROCESSING ==")
	PC_target = FileManager.source2pc(target,lod)
	target_points = FileManager.load_points(picked_target_)
	picked_target = Search.consistent_seeds(PC_target).([c[:] for c in eachcol(target_points)])

	PC_source = FileManager.source2pc(source,lod)
	source_points = FileManager.load_points(picked_source_)
	picked_source = Search.consistent_seeds(PC_source).([c[:] for c in eachcol(source_points)])

	ROTO = Registration.ICP(PC_target.coordinates,PC_source.coordinates,picked_target,picked_source; threshold = threshold)

	io = open(output_file,"w")
	write(io,"$(ROTO[1,1]) $(ROTO[1,2]) $(ROTO[1,3]) $(ROTO[1,4])\n")
	write(io,"$(ROTO[2,1]) $(ROTO[2,2]) $(ROTO[2,3]) $(ROTO[2,4])\n")
	write(io,"$(ROTO[3,1]) $(ROTO[3,2]) $(ROTO[3,3]) $(ROTO[3,4])\n")
	write(io,"$(ROTO[4,1]) $(ROTO[4,2]) $(ROTO[4,3]) $(ROTO[4,4])\n")
	close(io)

	#FileManager.successful(true,output_folder)
	# save new LAS source

	if isfile(source)
		aabb_original = FileManager.las2aabb(source)
		V,_,_ = Common.getmodel(aabb_original)
		new_V = Common.apply_matrix(ROTO,V)
		aabb = AABB(new_V)
		files = [source]
	else
		cloudmetadata = FileManager.CloudMetadata(source)
		aabb_original = cloudmetadata.tightBoundingBox
		V,_,_ = Common.getmodel(aabb_original)
		new_V = Common.apply_matrix(ROTO,V)
		aabb = AABB(new_V)
		trie = FileManager.potree2trie(source)
		files = FileManager.get_all_values(trie)
	end

	# creo l'header
	header_bb = AABB(-Inf, Inf,-Inf, Inf,-Inf, Inf)
	mainHeader = FileManager.newHeader(aabb,"REGISTRATION",FileManager.SIZE_DATARECORD)
	# apro il las
	temp = joinpath(splitdir(output)[1],"temp.las")
	open(temp, "w") do s
		write(s, LasIO.magic(LasIO.format"LAS"))
		for file in files
			h, laspoints = FileManager.read_LAS_LAZ(file) # read file
			for laspoint in laspoints # read each point
				point = Common.apply_matrix(ROTO,FileManager.xyz(laspoint,h)
				Common.update_boundingbox!(header_bb,point)
				plas = FileManager.newPointRecord(laspoint,h,LasIO.LasPoint2,mainHeader; affineMatrix = ROTO)
				write(s,plas) # write this record on temporary file
			end
		end
	end

	savepointcloud(
		mainHeader,
		header_bb,
		joinpath(splitdir(output)[1],"new_source.las"),
		n::Int64,
		temp::String,
		)

end

@time main()
