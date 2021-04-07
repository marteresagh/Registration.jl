"""
ICP Algorithm
"""
function ICP(target::Lar.Points, source::Lar.Points, picked_target::Array{Int64,1}, picked_source::Array{Int64,1})
	py"""
	import open3d as o3d
	import numpy as np

	def points2pcd(array_target_points,array_source_points,picked_id_target,picked_id_source):
		pcd_t = o3d.geometry.PointCloud()
		pcd_t.points = o3d.utility.Vector3dVector(np.array(array_target_points))

		pcd_s = o3d.geometry.PointCloud()
		pcd_s.points = o3d.utility.Vector3dVector(np.array(array_source_points))

		assert (len(picked_id_source) >= 3 and len(picked_id_target) >= 3)
		assert (len(picked_id_source) == len(picked_id_target))
		corr = np.zeros((len(picked_id_source), 2))
		corr[:, 0] = picked_id_source
		corr[:, 1] = picked_id_target

		# estimate rough transformation using correspondences
		print("Compute a rough transform using the correspondences given by user")
		p2p = o3d.pipelines.registration.TransformationEstimationPointToPoint()
		trans_init = p2p.compute_transformation(pcd_s, pcd_t,
		o3d.utility.Vector2iVector(corr))
		#
		# point-to-point ICP for refinement
		print("Perform point-to-point ICP refinement")
		threshold = 0.03  # 3cm distance threshold
		reg_p2p = o3d.pipelines.registration.registration_icp(
		pcd_s, pcd_t, threshold, trans_init,
		o3d.pipelines.registration.TransformationEstimationPointToPoint())
		#draw_registration_result(source, target, reg_p2p.transformation)
		print(reg_p2p)
		print(reg_p2p.transformation)
		return reg_p2p.transformation

	"""
	array_target_points = [c[:] for c in eachcol(target)]
	array_source_points = [c[:] for c in eachcol(source)]

	affineMatrix = py"points2pcd"(array_target_points,array_source_points,picked_target,picked_source)
	row1 = convert(Array,get(affineMatrix, 1 - 1))
	row2 = convert(Array,get(affineMatrix, 2 - 1))
	row3 = convert(Array,get(affineMatrix, 3 - 1))
	row4 = convert(Array,get(affineMatrix, 4 - 1))
	M = vcat(row1',row2',row3',row4')

	return M
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
