function down_sample(PC::Common.PointCloud,s)
	# default: 3cm distance threshold
	py"""
	import open3d as o3d
	import numpy as np

	def down_sample(points, colors, s):
		pcd = o3d.geometry.PointCloud()
		pcd.points = o3d.utility.Vector3dVector(np.array(points))
		pcd.colors = o3d.utility.Vector3dVector(np.array(colors))
		return pcd.voxel_down_sample(s)

	"""
	array_points = [c[:] for c in eachcol(PC.coordinates)]
	array_colors = [c[:] for c in eachcol(PC.rgbs)]

	pc_sampled = py"down_sample"(array_points,array_colors,s)

	return PointCloud(permutedims(pc_sampled.points),permutedims(pc_sampled.colors))
end
