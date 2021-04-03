
function fitafftrasf3D(target::Lar.Points,source::Lar.Points)
	x = source[1,:]
	y = source[2,:]
	z = source[3,:]
	u = target[1,:]
	v = target[2,:]
	w = target[3,:]
	npoints = size(source,2)
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


function res(R,T,source,target)
	newsource = R*source.+T
	for i in 1:size(source,2)
		val = Lar.norm(target[:,i]-newsource[:,i])
		println("$i => $val")
	end
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


function residuo(R,T,source,target)
	error = Lar.abs(Lar.norm(R*source.+T.-target)^2)
	return error
end
