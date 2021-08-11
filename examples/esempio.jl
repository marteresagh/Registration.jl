using Visualization
using Registration
using Search
using Common

PC = rand(3,8) # your path


PC_ref = Common.apply_matrix(Common.t(1.1,1.1,1.1), PC)


Visualization.VIEW([
	Visualization.axis_helper()
	Visualization.points(PC_ref; color = Visualization.WHITE)
	Visualization.points(PC; color = Visualization.RED)
]);

@time ROTO,fit,inli = Registration.georef(PC_ref,PC)


Visualization.VIEW([
	Visualization.axis_helper()
	Visualization.points(PC_ref; color = Visualization.WHITE)
	Visualization.points(Common.apply_matrix(ROTO,PC); color = Visualization.RED)
]);


picked = FileManager.load_points(raw"D:\potreeDirectory\pointclouds\CASALE_TARGET\picked.txt")

ref = Common.apply_matrix(Common.t(-Common.centroid(picked)...),picked)
