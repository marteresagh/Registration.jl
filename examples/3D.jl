using Visualization
using Registration
PC_target = FileManager.source2pc("D:/pointclouds/registration/casale_target.las",0)
target = "D:/pointclouds/registration/points_target.txt"
target_points = FileManager.load_points(target)
picked_target = Common.consistent_seeds(PC_target).([c[:] for c in eachcol(target_points)])

PC_source = FileManager.source2pc("D:/pointclouds/registration/casale_source.las",0)
source ="D:/pointclouds/registration/points_source.txt"
source_points = FileManager.load_points(source)
picked_source = Common.consistent_seeds(PC_source).([c[:] for c in eachcol(source_points)])

GL.VIEW([
	Visualization.points_color_from_rgb(Common.apply_matrix(Lar.t(-centroid...),PC_source.coordinates),PC_source.rgbs)
	# Visualization.points_color_from_rgb(Common.apply_matrix(Lar.t(-centroid...),Common.apply_matrix(ROTO,PC_source.coordinates)),PC_source.rgbs)
	Visualization.points_color_from_rgb(Common.apply_matrix(Lar.t(-centroid...),PC_target.coordinates),PC_target.rgbs)
]);


ROTO = Registration.ICP(PC_target.coordinates,PC_source.coordinates,picked_target,picked_source)

centroid = Common.centroid(PC_source.coordinates)

GL.VIEW([
	# Visualization.points_color_from_rgb(Common.apply_matrix(Lar.t(-centroid...),PC_source.coordinates),PC_source.rgbs)
	Visualization.points_color_from_rgb(Common.apply_matrix(Lar.t(-centroid...),Common.apply_matrix(ROTO,PC_source.coordinates)),PC_source.rgbs)
	Visualization.points_color_from_rgb(Common.apply_matrix(Lar.t(-centroid...),PC_target.coordinates),PC_target.rgbs)
]);
