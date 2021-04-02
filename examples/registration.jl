using Common
using Visualization
using AlphaStructures

## versione 1

X=rand(2,1000)

# R = [0.5 0 0.866025; 0.866025 0 -0.5; 0 1 0]
# t = [1,1,1]

r = [0.5 -sqrt(3)/2; sqrt(3)/2 0.5]
t = [1,2]
s=[1.4 0;0 0.5]

Y = r*s*X.+t
Y = AlphaStructures.matrixPerturbation(Y,atol=0.01)
GL.VIEW([
	GL.GLPoints(convert(Lar.Points,X'))
	GL.GLPoints(convert(Lar.Points,Y'), GL.COLORS[2])
	GL.GLFrame2
]);


R,T=ICP(X,Y)
X2 = R*X.+T
residuo(R,T,X,Y)
GL.VIEW([
	GL.GLPoints(convert(Lar.Points,X2'))
	GL.GLPoints(convert(Lar.Points,Y'), GL.COLORS[2])
	GL.GLFrame2
]);


R,T,iter,er=iterativeICP(X,Y,1000)
residuo(R,T,X,Y)
X2 = R*X.+T
GL.VIEW([
	GL.GLPoints(convert(Lar.Points,X2'))
	GL.GLPoints(convert(Lar.Points,Y'), GL.COLORS[2])
	GL.GLFrame2
]);


## versione 2
X=hcat([[1738.046, 958.344],[2791.177,2563.955],[292.847,1960.692],[3341.427,3282.396]]...)

Y=hcat([[702.328,-7360.435],[883.796,-7091.401],[456.396,-7189.547],[976.040,-6969.580]]...)


@time R,t = trasformazioneaffine2D(X,Y)

res(R,t,X,Y)

newX=R*X.+t
GL.VIEW([
	GL.GLPoints(convert(Lar.Points,newX'))
	GL.GLPoints(convert(Lar.Points,Y'), GL.COLORS[2])
	GL.GLFrame2
]);


X = rand(2,1000)

Y,_=Lar.apply(Lar.t(1,2),Lar.apply(Lar.r(pi/4),(X,[[1]])))

GL.VIEW([
	GL.GLPoints(convert(Lar.Points,newX'))
	GL.GLPoints(convert(Lar.Points,Y'), GL.COLORS[2])
	GL.GLFrame2
]);
