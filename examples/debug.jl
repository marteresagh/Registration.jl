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


#### AABB dei punti passati
aabb_target_points = AABB(target_points)
aabb_source_points = AABB(source_points)
aabb_target = Common.getmodel(aabb_target_points)
aabb_source = Common.getmodel(aabb_source_points)

M_T = Common.t(Common.centroid(aabb_target[1])...)*Common.s(2.,2.,2.)*Common.t(-Common.centroid(aabb_target[1])...)
T = Common.apply_matrix(M_T,aabb_target[1])
M_S = Common.t(Common.centroid(aabb_source[1])...)*Common.s(2.,2.,2.)*Common.t(-Common.centroid(aabb_source[1])...)
S = Common.apply_matrix(M_S,aabb_source[1])

aabb_target = (T,aabb_target[2],aabb_target[3])
aabb_source = (S,aabb_source[2],aabb_source[3])
Visualization.VIEW([
	Visualization.points(Common.apply_matrix(Common.t(-centroid...),PC_source.coordinates),PC_source.rgbs)
	Visualization.points(Common.apply_matrix(Common.t(-centroid...),PC_target.coordinates),PC_target.rgbs)

	Visualization.GLGrid(Common.apply_matrix(Common.t(-centroid...),aabb_target[1]),aabb_target[2])
	Visualization.GLGrid(Common.apply_matrix(Common.t(-centroid...),aabb_source[1]),aabb_source[2])
]);

subpotree("C:/Users/marte/Documents/potreeDirectory/pointclouds/CASALE_TARGET",aabb_target )
