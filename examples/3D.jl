using Visualization
using Registration
PC_target = FileManager.source2pc("D:/pointclouds/registration/casale_target.las",0) # your path
target = "D:/pointclouds/registration/points_target.txt" # your path
target_points = FileManager.load_points(target)
picked_target = Common.consistent_seeds(PC_target).([c[:] for c in eachcol(target_points)])
centroid = Common.centroid(PC_target.coordinates)

PC_source = FileManager.source2pc("D:/pointclouds/registration/casale_source.las",0) # your path
source ="D:/pointclouds/registration/points_source.txt" # your path
source_points = FileManager.load_points(source)
picked_source = Common.consistent_seeds(PC_source).([c[:] for c in eachcol(source_points)])

GL.VIEW([
	Visualization.points(Common.apply_matrix(Common.Lar.t(-centroid...),PC_source.coordinates),PC_source.rgbs)
	Visualization.points(Common.apply_matrix(Common.Lar.t(-centroid...),PC_target.coordinates),PC_target.rgbs)
]);


ROTO = Registration.ICP(PC_target.coordinates,PC_source.coordinates,picked_target,picked_source)


GL.VIEW([
	Visualization.points(Common.apply_matrix(Common.Lar.t(-centroid...),Common.apply_matrix(ROTO,PC_source.coordinates)),PC_source.rgbs)
	Visualization.points(Common.apply_matrix(Common.Lar.t(-centroid...),PC_target.coordinates),PC_target.rgbs)
]);
