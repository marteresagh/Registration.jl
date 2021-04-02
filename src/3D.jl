
function fitafftrasf3D(X::Lar.Points,Y::Lar.Points)
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


function res(R,T,X,Y)
	newX = R*X.+T
	for i in 1:size(X,2)
		val = Lar.norm(Y[:,i]-newX[:,i])
		println("$i => $val")
	end
end

function iterativeICP(X,Y,itermax)
	x=copy(X)
	iter=1
	R=Matrix(Lar.I,2,2)
	T=[0,0]
	error=diff=Inf
	while diff>1.e-8 && iter<itermax
		r,t = ICP(x,Y)
		R=r*R
		T=r*T+t
		diff=Lar.abs(error-residuo(R,T,X,Y))
		error=residuo(R,T,X,Y)
		@show diff
		x=r*x.+t
		iter+=1
	end
	return R,T,iter,error
end


function residuo(R,T,X,Y)
	error = Lar.abs(Lar.norm(R*X.+T.-Y)^2)
	return error
end
