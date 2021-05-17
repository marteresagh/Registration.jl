using Visualization
using Registration
using Search
using Common

PC_target = PointCloud(rand(3,100))
picked_target = [1,3,5,7,9]

matrix = Common.r(0,0,pi/2)
PC_source = PointCloud(Common.apply_matrix(matrix,PC_target.coordinates))
picked_source = [4,12,56,98,34]

Visualization.VIEW([
	Visualization.points(PC_target.coordinates; color = Visualization.COLORS[1])
	Visualization.points(PC_source.coordinates; color = Visualization.COLORS[2])
	Visualization.points(PC_target.coordinates[:,picked_target]; color = Visualization.COLORS[3])
	Visualization.points(PC_source.coordinates[:,picked_source]; color = Visualization.COLORS[4])
]);


ROTO = Registration.ICP(PC_target.coordinates,PC_source.coordinates,picked_target,picked_source)


Visualization.VIEW([
	Visualization.points(Common.apply_matrix(ROTO,PC_source.coordinates); color = Visualization.COLORS[2])
	Visualization.points(PC_target.coordinates;color = Visualization.COLORS[1] )
]);
