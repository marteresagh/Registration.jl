"""
	ICP(target::Lar.Points, source::Lar.Points, picked_target::Array{Int64,1}, picked_source::Array{Int64,1}) -> Matrix

Return affine transformation to combine two point clouds into a global consistent model.

In the Iterative Closest Point one point cloud the reference, or target, is kept fixed,
while the other one, the source, is transformed to best match the reference.

# Parameters
 - target: coordinates points of target point cloud
 - source: coordinates points of source point cloud
 - picked_id_target: id of points picked in target point cloud
 - picked_id_source: id of points picked in source point cloud
 - threshold: distance threshold
"""
# no scaling
function ICP(target::Points, source::Points, picked_id_target::Array{Int64,1}, picked_id_source::Array{Int64,1}; threshold = 0.03::Float64, max_it=2000::Int64)
	# default: 3cm distance threshold
	py"""
	import open3d as o3d
	import numpy as np

	def points2pcd(array_target_points,array_source_points,picked_id_target,picked_id_source,threshold,max_it):
		pcd_t = o3d.geometry.PointCloud()
		pcd_t.points = o3d.utility.Vector3dVector(np.array(array_target_points))

		pcd_s = o3d.geometry.PointCloud()
		pcd_s.points = o3d.utility.Vector3dVector(np.array(array_source_points))

		assert (len(picked_id_source) >= 3 and len(picked_id_target) >= 3)
		assert (len(picked_id_source) == len(picked_id_target))
		corr = np.zeros((len(picked_id_source), 2))
		corr[:, 0] = picked_id_source -1
		corr[:, 1] = picked_id_target -1

		# estimate rough transformation using correspondences
		print("Compute a rough transform using the correspondences given by user")
		p2p = o3d.pipelines.registration.TransformationEstimationPointToPoint()
		trans_init = p2p.compute_transformation(pcd_s, pcd_t,
		o3d.utility.Vector2iVector(corr))
		print()
		print("First transformation is:")
		print(trans_init)

		# evaluation
		evaluation = o3d.pipelines.registration.evaluate_registration(pcd_s, pcd_t,
		threshold, trans_init)
		print("fitness: ", evaluation.fitness)
		print("inliers rmse: ", evaluation.inlier_rmse)

		# point-to-point ICP for refinement
		print()
		print("Perform point-to-point ICP refinement")
		reg_p2p = o3d.pipelines.registration.registration_icp(pcd_s, pcd_t, threshold, trans_init,o3d.pipelines.registration.TransformationEstimationPointToPoint(),o3d.pipelines.registration.ICPConvergenceCriteria(max_iteration=max_it))

		print(reg_p2p)
		print("Transformation is:")
		print(reg_p2p.transformation)
		return reg_p2p

	"""
	array_target_points = [c[:] for c in eachcol(target)]
	array_source_points = [c[:] for c in eachcol(source)]
	println("prima di entrare",picked_id_source,picked_id_target)
	reg_p2p = py"points2pcd"(array_target_points,array_source_points,picked_id_target,picked_id_source,threshold,max_it)
	affineMatrix = reg_p2p.transformation

	row1 = convert(Array,get(affineMatrix, 1 - 1))
	row2 = convert(Array,get(affineMatrix, 2 - 1))
	row3 = convert(Array,get(affineMatrix, 3 - 1))
	row4 = convert(Array,get(affineMatrix, 4 - 1))
	M = vcat(row1',row2',row3',row4')

	return M, reg_p2p.fitness, reg_p2p.inlier_rmse, reg_p2p.correspondence_set
end

#
# function fitafftrasf3D(target::Lar.Points,source::Lar.Points)
# 	x = source[1,:]
# 	y = source[2,:]
# 	z = source[3,:]
# 	u = target[1,:]
# 	v = target[2,:]
# 	w = target[3,:]
# 	npoints = size(source,2)
# 	phi = [ x y z ones(npoints) zeros(npoints,4) zeros(npoints,4);
# 			zeros(npoints,4) x y z ones(npoints) zeros(npoints,4);
# 			zeros(npoints,4) zeros(npoints,4) x y z ones(npoints)]
# 	A = phi'*phi
# 	b = phi'*[u;v;w]
# 	params = A\b
#
# 	R = [ params[1] params[2] params[3];
# 		  params[5] params[6] params[7] ;
# 		  params[9] params[10] params[11] ]
#
# 	t = [params[4], params[8], params[12]]
# 	return R,t
# end
#
#
# function res(R,T,source,target)
# 	newsource = R*source.+T
# 	for i in 1:size(source,2)
# 		val = Lar.norm(target[:,i]-newsource[:,i])
# 		println("$i => $val")
# 	end
# end
#
# function iterative(target,source,itermax)
# 	x=copy(source)
# 	iter=1
# 	R=Matrix(Lar.I,3,3)
# 	T=[0,0,0]
# 	error=diff=Inf
# 	while diff>1.e-8 && iter<itermax
# 		r,t = ICP(x,target)
# 		R=r*R
# 		T=r*T+t
# 		diff=Lar.abs(error-residuo(R,T,source,target))
# 		error=residuo(R,T,source,target)
# 		@show diff
# 		x=r*x.+t
# 		iter+=1
# 	end
# 	return R,T,iter,error
# end
#
#
# function residuo(R,T,source,target)
# 	error = Lar.abs(Lar.norm(R*source.+T.-target)^2)
# 	return error
# end
