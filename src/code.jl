
"""
X la source cloud
Y è la reference cloud
"""
function ICP(X,Y)
	x=X[1,:]
	y=X[2,:]
	u=Y[1,:]
	v=Y[2,:]
	sx2=Lar.norm(x)^2
	sxy=Lar.dot(x,y)
	sx=sum(x)
	sy2=Lar.norm(y)^2
	sy=sum(y)
	n=size(X,2)
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



function trasformazioneaffine2D(X::Lar.Points,Y::Lar.Points)
	x=X[1,:]
	y=X[2,:]
	u=Y[1,:]
	v=Y[2,:]
	sx2=Lar.norm(x)^2
	sxy=Lar.dot(x,y)
	sx=sum(x)
	sy2=Lar.norm(y)^2
	sy=sum(y)
	n=size(X,2)
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


## uso la versione 2
function fitafftrasf2D(X::Lar.Points,Y::Lar.Points)
	x = X[1,:]
	y = X[2,:]
	u = Y[1,:]
	v = Y[2,:]
	npoints=size(X,2)
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
