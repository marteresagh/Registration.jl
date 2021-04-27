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
end

@time main()
