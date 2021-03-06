using Visualization
using Registration
using Search
using Common
using AlphaStructures

PC_target = PointCloud(rand(3,100)) # your path
picked_target = [1,2,3,4,5,6,7,8]

PC_source = PointCloud(Common.apply_matrix(Common.s(1.1,1.1,1.1), PC_target.coordinates))# your path
picked_source = [1,2,3,4,5,6,7,8]

Visualization.VIEW([
	Visualization.points(PC_source.coordinates; color = Visualization.WHITE)
	Visualization.points(PC_target.coordinates; color = Visualization.RED)
]);


@time ROTO,_ = Registration.ICP(PC_target.coordinates,PC_source.coordinates,picked_target,picked_source;threshold = 3.)


Visualization.VIEW([
	Visualization.points(Common.apply_matrix(ROTO,PC_source.coordinates); color = Visualization.WHITE)
	Visualization.points(PC_target.coordinates; color = Visualization.RED)
]);
