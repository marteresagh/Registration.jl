using Common
using Registration

GCP_SULLA_NUVOLA = [502160.3700 4464714.3300 280.7310;
					502177.5570	4464713.4210 280.5810;
					502176.4270	4464739.8130 278.2860;
					502167.7960	4464740.4250 278.8660]

GCP_SULLA_NUVOLA = permutedims(GCP_SULLA_NUVOLA)

GCP_FILE_RW5 = [502246.15	4464907.46	222.3005;
			502263.45	4464906.49	221.9957;
			502262.43	4464933.04	219.4388;
			502254.4300	4464932.04 219.4388
			]

GCP_FILE_RW5 = permutedims(GCP_FILE_RW5)


GCP_LOC = [0.0000	0.0000	265.8900;
			17.3123	-0.9695	265.5791;
			16.2912	25.5764	263.0238]

GCP_LOC = permutedims(GCP_LOC)
#
# GCP = [
#         502160.370 502177.557 502176.427 502167.769
#         4464714.330 4464713.421 4464739.813 4464740.425
#         280.731 280.581 278.286 278.866
# ]
#
# GCP_LOC = [
#         0 17.3123 16.2912
#         0 -0.9695 25.5764
#         265.89 265.5791 263.0238
# ]
#



function fitafftrasf3D(X::Common.Points,Y::Common.Points)
	x = X[1,:]
	y = X[2,:]
	z = X[3,:]
	u = Y[1,:]
	v = Y[2,:]
	w = Y[3,:]
	npoints = size(X,2)
	phi = [ x y z ones(npoints) zeros(npoints,4) zeros(npoints,4);
			zeros(npoints,4) x y z ones(npoints) zeros(npoints,4);
			zeros(npoints,4) zeros(npoints,4) x y z ones(npoints)]
	A = phi'*phi
	b = phi'*[u;v;w]
	params = A\b

	R = [ params[1] params[2] params[3];
		  params[5] params[6] params[7] ;
		  params[9] params[10] params[11] ]

	t = [params[4], params[8], params[12]]
	return R,t
end

R,t = fitafftrasf3D(GCP_SULLA_NUVOLA[:,1:end-1],GCP_FILE_RW5)
M = Common.matrix4(R)
M[1:3,4] = t

Common.apply_matrix(M,GCP_SULLA_NUVOLA)

R,t = fitafftrasf3D(GCP_FILE_RW5[:,1:end-1], GCP_LOC)
T = Common.matrix4(R)
T[1:3,4] = t

Common.apply_matrix(T,GCP_FILE_RW5)


GCP4_LOC =  Common.apply_matrix(T,GCP_FILE_RW5)
GCP4_RW5 = [502254.4300, 4464932.04, 219.4388]
GCP4_LOC = [8.53006, 27.4162, 263.027]

using Visualization
Visualization.VIEW([
	Visualization.points(GCP_LOC; color = Visualization.COLORS[2]),
	Visualization.points(Common.apply_matrix(T*M,GCP_SULLA_NUVOLA)),
	#Visualization.points(GCP4_LOC; color = Visualization.COLORS[3])
])


# RISULTATO !!!!!!!!!!!!!!!!!!!!!!!!!
GCP4_LOC = [ 6.7818, 20.3922, 263.75]


R,t = fitafftrasf3D(GCP[:,1:end-1],GCP_LOC)
ROTO = Common.matrix4(R)
ROTO[1:3,4] = t

# ROTO, fitness, rmse, corr_set = Registration.compute_transformation(GCP_SULLA_NUVOLA[:,1:end-1],GCP_FILE_RW5)
#
# Common.apply_matrix(ROTO,GCP_FILE_RW5)
#
# function fitafftrasf2D(target::Common.Points,source::Common.Points)
# 	x = source[1,:]
# 	y = source[2,:]
# 	u = target[1,:]
# 	v = target[2,:]
# 	npoints=size(source,2)
# 	phi = [ x y ones(npoints) zeros(npoints,3) ;
# 			zeros(npoints,3) x y ones(npoints) ]
# 	A = phi'*phi
# 	b = phi'*[u;v]
# 	params = A\b
#
# 	R = [ params[1] params[2];
# 		params[4] params[5]]
#
# 	t = [params[3], params[6]]
# 	return R,t
# end
#
# R,t = fitafftrasf2D(GCP_LOC[1:2,:],GCP[1:2,1:end-1])
# ROTO = Common.matrix3(R)
# ROTO[1:2,3] = t
#
# Common.apply_matrix(ROTO,GCP[1:2,:])
