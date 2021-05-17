using Visualization
using Registration
using Search
using Common

PC_target = FileManager.source2pc("D:/pointclouds/registration/casale_target.las",0) # your path
model_target = Common.getmodel(FileManager.las2aabb("D:/pointclouds/registration/casale_target.las"))

target = "D:/pointclouds/registration/points_target.txt" # your path
target_points = FileManager.load_points(target)
picked_target = Search.consistent_seeds(PC_target).([c[:] for c in eachcol(target_points)])
centroid = Common.centroid(PC_target.coordinates)

PC_source = FileManager.source2pc("D:/pointclouds/registration/casale_source.las",0) # your path
model_source = Common.getmodel(FileManager.las2aabb("D:/pointclouds/registration/casale_source.las"))

source ="D:/pointclouds/registration/points_source.txt" # your path
source_points = FileManager.load_points(source)
picked_source = Search.consistent_seeds(PC_source).([c[:] for c in eachcol(source_points)])

Visualization.VIEW([
	Visualization.points(Common.apply_matrix(Common.t(-centroid...),PC_source.coordinates),PC_source.rgbs)
	Visualization.points(Common.apply_matrix(Common.t(-centroid...),PC_target.coordinates),PC_target.rgbs)
]);


ROTO,_ = Registration.ICP(PC_target.coordinates,PC_source.coordinates,picked_target,picked_source)


Visualization.VIEW([
	Visualization.points(Common.apply_matrix(Common.t(-centroid...),PC_source.coordinates),PC_source.rgbs)
	Visualization.points(Common.apply_matrix(Common.t(-centroid...),PC_target.coordinates),PC_target.rgbs)

	Visualization.GLGrid(Common.apply_matrix(Common.t(-centroid...),model_target[1]),model_target[2])
	Visualization.GLGrid(Common.apply_matrix(Common.t(-centroid...),model_source[1]),model_source[2])
]);
