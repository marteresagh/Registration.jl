println("loading packages... ")

using ArgParse
using Registration

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
	"--output", "-o"
		help = "Output folder"
		required = true
	end

	return parse_args(s)
end

function main()
	args = parse_commandline()

	target = args["target"]
	source = args["source"]
	output_folder = args["output"]

	source_points = FileManager.load_points(source)
	target_points = FileManager.load_points(target)
	R,T = fitafftrasf3D(target_points,source_points)

	ROTO = Registration.Common.matrix4(R)
	ROTO[1:3,4] = T

	io = open(joinpath(output_folder,"rototraslazione.txt")
	write(io,"$(ROTO[1,1]) $(ROTO[1,2]) $(ROTO[1,3]) $(ROTO[1,4])\n")
	write(io,"$(ROTO[2,1]) $(ROTO[2,2]) $(ROTO[2,3]) $(ROTO[2,4])\n")
	write(io,"$(ROTO[3,1]) $(ROTO[3,2]) $(ROTO[3,3]) $(ROTO[3,4])\n")
	write(io,"$(ROTO[4,1]) $(ROTO[4,2]) $(ROTO[4,3]) $(ROTO[4,4])\n")
	close(io)
end

@time main()
