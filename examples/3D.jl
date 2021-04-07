using Registration
using FileManager
using Visualization
using Common
source ="D:/pointclouds/registration/points_source.txt"
target = "D:/pointclouds/registration/points_target.txt"
output_folder = "D:/pointclouds/registration"
source_points = FileManager.load_points(source)
target_points = FileManager.load_points(target)
R,T = Registration.fitafftrasf3D(target_points,source_points)
ROTO = Registration.Common.matrix4(R)
ROTO[1:3,4] = T

# ROTO = Matrix{Float64}(Lar.I,4,4)
#
# ROTO[1,1] = -0.442
# ROTO[1,2] = -0.582
# ROTO[1,3] = 0.683
# ROTO[1,4] = 6.457
#
# ROTO[2,1] = 0.896
# ROTO[2,2] = -0.239
# ROTO[2,3] = 0.376
# ROTO[2,4] = -5.478
#
# ROTO[3,1] = -0.055
# ROTO[3,2] = 0.778
# ROTO[3,3] = 0.626
# ROTO[3,4] = -4.037
#

PC_source = FileManager.source2pc("D:/pointclouds/registration/casale_source.las",0)
PC_target = FileManager.source2pc("D:/pointclouds/registration/casale_target.las",0)
centroid = Common.centroid(PC_source.coordinates)
GL.VIEW([
	# Visualization.points_color_from_rgb(Common.apply_matrix(Lar.t(-centroid...),PC_source.coordinates),PC_source.rgbs)
	Visualization.points_color_from_rgb(Common.apply_matrix(Lar.t(-centroid...),Common.apply_matrix(ROTO,PC_source.coordinates)),PC_source.rgbs)
	Visualization.points_color_from_rgb(Common.apply_matrix(Lar.t(-centroid...),PC_target.coordinates),PC_target.rgbs)
]);
