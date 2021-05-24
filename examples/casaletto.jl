using Visualization
using Registration
using Search

file_target = joinpath(raw"C:\Users\marte\Documents\GEOWEB\TEST\REGISTRATION","target_segment.las")
PC_target = FileManager.source2pc(file_target,-1) # your path
target = raw"D:\registration\casaletto\target.txt" # your path
target_points = FileManager.load_points(target)
picked_target = Search.consistent_seeds(PC_target).([c[:] for c in eachcol(target_points)])
centroid = Common.centroid(PC_target.coordinates)


file_source = joinpath(raw"C:\Users\marte\Documents\GEOWEB\TEST\REGISTRATION","source_segment.las")
PC_source = FileManager.source2pc(file_source,-1) # your path
source = raw"D:\registration\casaletto\source.txt" # your path
source_points = FileManager.load_points(source)
picked_source = Search.consistent_seeds(PC_source).([c[:] for c in eachcol(source_points)])

Visualization.VIEW([
	# Visualization.points(Common.apply_matrix(Common.t(-centroid...),PC_source.coordinates),PC_source.rgbs)
	Visualization.points(Common.apply_matrix(Common.t(-centroid...),PC_target.coordinates),PC_target.rgbs)
	# Visualization.points(Common.apply_matrix(Common.t(-centroid...),source_points); color = Visualization.RED )
	Visualization.points(Common.apply_matrix(Common.t(-centroid...),target_points); color = Visualization.GREEN)
]);


ROTO,_ = Registration.ICP(PC_target.coordinates,PC_source.coordinates,picked_target,picked_source; threshold = 0.01)


Visualization.VIEW([
	Visualization.points(Common.apply_matrix(Common.t(-centroid...),Common.apply_matrix(ROTO,PC_source.coordinates)),PC_source.rgbs)
	Visualization.points(Common.apply_matrix(Common.t(-centroid...),PC_target.coordinates),PC_target.rgbs)
]);
