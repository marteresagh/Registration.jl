"""
In the Iterative Closest Point one point cloud the reference, or target, is kept fixed,
while the other one, the source, is transformed to best match the reference.
source è la source cloud (si muove)
target è la reference cloud (ferma = master)
"""
function ICP(target::Lar.points,source::Lar.Points)
	x=source[1,:]
	y=source[2,:]
	u=target[1,:]
	v=target[2,:]
	sx2=Lar.norm(x)^2
	sxy=Lar.dot(x,y)
	sx=sum(x)
	sy2=Lar.norm(y)^2
	sy=sum(y)
	n=size(source,2)
	sux=Lar.dot(u,x)
	suy=Lar.dot(u,y)
	su=sum(u)
	svx=Lar.dot(v,x)
	svy=Lar.dot(v,y)
	sv=sum(v)
	A=[ sx2 sxy sx 0 0 0;
		sxy sy2 sy 0 0 0;
		sx  sy  n  0 0 0;
		0 0 0  sx2 sxy sx;
		0 0 0  sxy sy2 sy;
		0 0 0  sx  sy  n]
	b=[sux, suy, su, svx, svy, sv]
	params=A\b

	R=[ params[1] params[2];
		params[4] params[5]]

	t=[params[3], params[6]]
	return R,t
end



function trasformazioneaffine2D(source::Lar.Points,target::Lar.Points)
	x=source[1,:]
	y=source[2,:]
	u=target[1,:]
	v=target[2,:]
	sx2=Lar.norm(x)^2
	sxy=Lar.dot(x,y)
	sx=sum(x)
	sy2=Lar.norm(y)^2
	sy=sum(y)
	n=size(source,2)
	sux=Lar.dot(u,x)
	suy=Lar.dot(u,y)
	su=sum(u)
	svx=Lar.dot(v,x)
	svy=Lar.dot(v,y)
	sv=sum(v)

	block = [  sx2 sxy sx;
				sxy sy2 sy;
				sx  sy  n  ]

	zero = zeros(3,3)

	A = [block zero; zero block]
	b=[sux, suy, su, svx, svy, sv]
	params=A\b

	R = [ params[1] params[2];
		params[4] params[5]]

	t = [params[3], params[6]]
	return R,t
end



# uso la versione 2
function fitafftrasf2D(source::Lar.Points,target::Lar.Points)
	x = source[1,:]
	y = source[2,:]
	u = target[1,:]
	v = target[2,:]
	npoints=size(source,2)
	phi = [ x y ones(npoints) zeros(npoints,3) ;
			zeros(npoints,3) x y ones(npoints) ]
	A = phi'*phi
	b = phi'*[u;v]
	params = A\b

	R = [ params[1] params[2];
		params[4] params[5]]

	t = [params[3], params[6]]
	return R,t
end


function iterativeICP(source,target,itermax)
	x=copy(source)
	iter=1
	R=Matrix(Lar.I,2,2)
	T=[0,0]
	error=diff=Inf
	while diff>1.e-8 && iter<itermax
		r,t = ICP(x,target)
		R=r*R
		T=r*T+t
		diff=Lar.abs(error-residuo(R,T,source,target))
		error=residuo(R,T,source,target)
		@show diff
		x=r*x.+t
		iter+=1
	end
	return R,T,iter,error
end
