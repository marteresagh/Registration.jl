using Visualization
using Registration
using Search

PC_target = FileManager.source2pc("D:/pointclouds/registration/casale_target.las",0) # your path
target = "D:/pointclouds/registration/points_target.txt" # your path
target_points = FileManager.load_points(target)
picked_target = Search.consistent_seeds(PC_target).([c[:] for c in eachcol(target_points)])
centroid = Common.centroid(PC_target.coordinates)

PC_source = FileManager.source2pc("D:/pointclouds/registration/casale_source.las",0) # your path
source ="D:/pointclouds/registration/points_source.txt" # your path
source_points = FileManager.load_points(source)
picked_source = Search.consistent_seeds(PC_source).([c[:] for c in eachcol(source_points)])

Visualization.VIEW([
	Visualization.points(Common.apply_matrix(Common.t(-centroid...),PC_source.coordinates),PC_source.rgbs)
	Visualization.points(Common.apply_matrix(Common.t(-centroid...),PC_target.coordinates),PC_target.rgbs)
]);


ROTO,_ = Registration.ICP(PC_target.coordinates,PC_source.coordinates,picked_target,picked_source; threshold = 0.2)

Visualization.VIEW([
#	Visualization.points(PC; alpha = 0.2)
	Visualization.points(Common.apply_matrix(Common.t(-centroid...),OUT))
])


Visualization.VIEW([
	Visualization.points(Common.apply_matrix(Common.t(-centroid...),Common.apply_matrix(ROTO,PC_source.coordinates)),PC_source.rgbs)
	Visualization.points(Common.apply_matrix(Common.t(-centroid...),PC_target.coordinates),PC_target.rgbs)
]);


PC = PointCloud(hcat(PC_target.coordinates,Common.apply_matrix(ROTO,PC_source.coordinates)),hcat(PC_target.rgbs,PC_source.rgbs))
OUT = Registration.down_sample(PC,0.001)

Visualization.VIEW([
#	Visualization.points(PC; alpha = 0.2)
	Visualization.points(Common.apply_matrix(Common.t(-centroid...),OUT.coordinates),OUT.rgbs)
])
