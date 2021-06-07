using Visualization
using Registration
using Search
using FileManager
using Common
using OrthographicProjection


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
				write(t,plas)
				flush(t)
			end
		end
		Registration.flushprintln("Save target points...")
		for file in files_target
			h, laspoints = FileManager.read_LAS_LAZ(file) # read file
			for laspoint in laspoints # read each point
				plas = FileManager.newPointRecord(laspoint,h,Registration.LasIO.LasPoint2,mainHeader)
				write(t,plas)
				flush(t)
			end
		end
	close(t)

	Registration.flushprintln("Point cloud: done ...")
end


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

	target = raw"D:\registration\VIGNA_MURATA_SCAN_2\VIGNA_MURATA_TARGET"
	source = raw"D:\registration\VIGNA_MURATA_SCAN_1\VIGNA_MURATA_SOURCE"
	picked_target_ = raw"D:\registration\targetPoints.csv"
	picked_source_ = raw"D:\registration\sourcePoints.csv"
	output_folder = raw"D:\registration"
	proj_name = "VIGNA"
	threshold = 0.03
	scale = 1.5

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


	ROTO, fitness, rmse, corr_set = Registration.ICP(PC_target.coordinates,PC_source.coordinates,picked_target,picked_source; threshold = threshold)

	io = open(joinpath(output_folder,proj_name*".rtm"),"w")
	write(io,"$(ROTO[1,1]) $(ROTO[1,2]) $(ROTO[1,3]) $(ROTO[1,4])\n")
	write(io,"$(ROTO[2,1]) $(ROTO[2,2]) $(ROTO[2,3]) $(ROTO[2,4])\n")
	write(io,"$(ROTO[3,1]) $(ROTO[3,2]) $(ROTO[3,3]) $(ROTO[3,4])\n")
	write(io,"$(ROTO[4,1]) $(ROTO[4,2]) $(ROTO[4,3]) $(ROTO[4,4])\n")
	close(io)

	# save new LAS source
	# if isfile(source) && isfile(target)
	# 	aabb_original = FileManager.las2aabb(source)
	# 	V,_,_ = Common.getmodel(aabb_original)
	# 	new_V = Common.apply_matrix(ROTO,V)
	# 	aabb_source = Registration.AABB(new_V)
	# 	files_source = [source]
	#
	# 	aabb_target = FileManager.las2aabb(target)
	# 	files_target = [target]
	# else
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

	n_points = n_target+n_source
	savepointcloud(files_source, files_target, aabb, joinpath(output_folder,proj_name*".las"), n_points, ROTO)

	FileManager.successful(true,output_folder; message = "fitness: $fitness\ninlier_rmse: $rmse\ncorrespondence_set: $(size(corr_set,1))")
end

@time main()
#
# PC_target = FileManager.source2pc("C:/Users/marte/Documents/potreeDirectory/pointclouds/CASALE_TARGET",-1) # your path
# target = "D:/pointclouds/registration/points_target.txt" # your path
# target_points = FileManager.load_points(target)
# picked_target = Search.consistent_seeds(PC_target).([c[:] for c in eachcol(target_points)])
# centroid = Common.centroid(PC_target.coordinates)
#
# PC_source = FileManager.source2pc("C:/Users/marte/Documents/potreeDirectory/pointclouds/CASALE_SOURCE",0) # your path
# source ="D:/pointclouds/registration/points_source.txt" # your path
# source_points = FileManager.load_points(source)
# picked_source = Search.consistent_seeds(PC_source).([c[:] for c in eachcol(source_points)])
#
# Visualization.VIEW([
# 	Visualization.points(Common.apply_matrix(Common.t(-centroid...),PC_source.coordinates),PC_source.rgbs)
# 	Visualization.points(Common.apply_matrix(Common.t(-centroid...),PC_target.coordinates),PC_target.rgbs)
# ]);
#
#
# ROTO,_ = Registration.ICP(PC_target.coordinates,PC_source.coordinates,picked_target,picked_source)
#
#
# Visualization.VIEW([
# 	Visualization.points(Common.apply_matrix(Common.t(-centroid...),Common.apply_matrix(ROTO,PC_source.coordinates)),PC_source.rgbs)
# 	Visualization.points(Common.apply_matrix(Common.t(-centroid...),PC_target.coordinates),PC_target.rgbs)
# ]);
