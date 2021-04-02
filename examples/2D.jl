using Visualization
using AlphaStructures
using Registration
using Common
## versione 1

target = rand(2,1000)

r = [0.5 -sqrt(3)/2; sqrt(3)/2 0.5]
t = [1,2]
s = [1.4 0;0 0.5]
RST_originale = vcat(hcat(r*s,[0,0]),[0.,0.,1.]')
RST_originale[1:2,3] = t

source = Common.apply_matrix(RST_originale,target)
source = AlphaStructures.matrixPerturbation(source,atol=0.01)


GL.VIEW([
	GL.GLPoints(permutedims(source), GL.COLORS[2])
	GL.GLPoints(permutedims(Common.apply_matrix(Lar.inv(RST_originale),source)), GL.COLORS[2])
	GL.GLPoints(permutedims(target), GL.COLORS[1])
	GL.GLFrame2
]);


R,T = Registration.ICP(X,Y)
X2 = R*X.+T
residuo(R,T,X,Y)
GL.VIEW([
	GL.GLPoints(convert(Lar.Points,X2'))
	GL.GLPoints(convert(Lar.Points,Y'), GL.COLORS[2])
	GL.GLFrame2
]);


R,T,iter,er = Registration.iterativeICP(X,Y,1000)
residuo(R,T,X,Y)
X2 = R*X.+T
GL.VIEW([
	GL.GLPoints(convert(Lar.Points,X2'))
	GL.GLPoints(convert(Lar.Points,Y'), GL.COLORS[2])
	GL.GLFrame2
]);


X=hcat([[1738.046, 958.344],[2791.177,2563.955],[292.847,1960.692],[3341.427,3282.396]]...)

Y=hcat([[702.328,-7360.435],[883.796,-7091.401],[456.396,-7189.547],[976.040,-6969.580]]...)


@time R,t = Registration.trasformazioneaffine2D(X,Y)

res(R,t,X,Y)

newX=R*X.+t
GL.VIEW([
	GL.GLPoints(convert(Lar.Points,newX'))
	GL.GLPoints(convert(Lar.Points,Y'), GL.COLORS[2])
	GL.GLFrame2
]);
