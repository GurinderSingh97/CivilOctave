def funSaog(soilType, timePrd):
    t1 = 0; t2 = 0; t3 = 0; t4 = 0
    eq3num = 0
    t2 = 0.10
    if(soilType=='I'):
        t3 = 0.40; eq3num = 1.0
    elif (soilType=='II'):
        t3 = 0.55; eq3num = 1.36
    elif(soilType=='III'):
        t3 = 0.67; eq3num = 1.67
    else:
        Print('Unexpected soil type')
    if (timePrd < t2):
        sag = 1. + 15 * timePrd
    elif(timePrd > t3):
        sag = eq3num / timePrd
    else:
        sag = 2.5
    return sag
load('input.sage')
latex.matrix_delimiters("[","]")
Level_floor=zero_vector(RR,Number_of_storeys)
for storey_i in range(Number_of_storeys):
    Level_floor[storey_i] = Height_storey[storey_i,0]
    if(storey_i>0):
        Level_floor[storey_i]= Level_floor[storey_i]+Level_floor[storey_i - 1]
Stiffness_matrix=zero_matrix(QQ,4,4)
for storey_i in range(Number_of_storeys):
	Stiffness_matrix[storey_i, storey_i] = Stiffness_storey[storey_i][0]
	if (storey_i < Number_of_storeys-1):
		Stiffness_matrix[storey_i, storey_i] = Stiffness_matrix[storey_i, storey_i] + Stiffness_storey[storey_i + 1][0]
		Stiffness_matrix[storey_i, storey_i + 1] = - Stiffness_storey[storey_i + 1][0]
		Stiffness_matrix[storey_i + 1, storey_i] = Stiffness_matrix[storey_i, storey_i + 1]
w=var('w')
q=Stiffness_matrix-(w^2)*Mass
A=Stiffness_matrix*Mass.inverse()
Omega_square=A.eigenvalues()
Omega=zero_vector(RR,4)
Time_period=zero_matrix(RR,Number_of_storeys,Number_of_storeys)
for i in range( Number_of_storeys):
	q=sqrt(Omega_square[i])
	Omega[i]=q
	Time_period[i,i]=n(2*pi)/q
Time_periods=list()
for storey_i in range(Number_of_storeys):
	Time_periods.append(Time_period[storey_i, storey_i])
Frequency=list()
for storey_i in range(Number_of_storeys):
	Frequency.append(sqrt(Omega_square[storey_i].n(digits=4)))
z=A.eigenvectors_left()
J=list()
for x in range(Number_of_storeys):
	q=matrix(z[x][1][0])
	J.append(q*Mass*q.transpose())
X=list()
for x in range(Number_of_storeys):
	q=matrix(z[x][1][0])
	X.append(q/sqrt(abs(J[x])))
Modal_participation_factor=list()
Modal_mass=list()
sum_modal_mass=0
for j in range(Number_of_storeys):
        P1,P2=0,0
        m=matrix(X[j])
        for i in range(Number_of_storeys):
            P1=P1+Mass[i][i]*m[0][i]
            P2=P2+Mass[i][i]*(m[0][i])**2
        Modal_participation_factor.append(P1/P2)
        Modal_mass.append((P1)**2/(P2))
        sum_modal_mass = sum_modal_mass + Modal_mass[j]
Modal_contribution=list()
for i in range(Number_of_storeys):
	Modal_contribution.append(((100 / sum_modal_mass )*Modal_mass[i]).n(digits=4))
Type_of_soil=''
for i in range (Soil_type):
   Type_of_soil = Type_of_soil+'I'
Sa_by_g=zero_matrix(RR,4,4)
A_h=zero_matrix(RR,4,4)
for index_time in range(Number_of_storeys):
	Sa_by_g[index_time,1] = funSaog(Type_of_soil, Time_periods[index_time])
 	A_h[index_time,1] = Zone_factor/2*Importance_factor /Response_reduction_factor * Sa_by_g[index_time,1]

XX=zero_matrix(RR,4,4)
for i in range(Number_of_storeys):
    XX[:,i]=matrix(RR,X[i]).transpose()
Design_lateral_force=zero_matrix(RR,4,4)
for index_i in range(Number_of_storeys):
    q=Mass*XX[:,index_i]
    z=q*matrix(A_h[index_i] *Modal_participation_factor[index_i]* Gravity_acceleration)
    Design_lateral_force[: , index_i]=z[:,1]
Peak_shear_force = zero_matrix(RR,Number_of_storeys, Number_of_storeys)
for index_j in range(Number_of_storeys):
	for index_i in range(Number_of_storeys):
		for index_k in range(Number_of_storeys - index_i ):
			Peak_shear_force[index_i,index_j] = Design_lateral_force[index_k + index_i,index_j] + Peak_shear_force[index_i,index_j]
Storey_shear_force = zero_matrix(RR,Number_of_storeys, Number_of_storeys)
if (Modes_considered == 0):
  Modes_considered = Number_of_modes_to_be_considered
for index_i in range(Number_of_storeys):
    for index_j in range(Modes_considered):
        Storey_shear_force[index_i,1] = Storey_shear_force[index_i,1] + abs(Peak_shear_force[index_i,index_j])
        Storey_shear_force[index_i,2] = Storey_shear_force[index_i,2] + Peak_shear_force[index_i,index_j]^2
    Storey_shear_force[index_i,2] = sqrt(Storey_shear_force[index_i,2])
P=zero_matrix(RR,Number_of_storeys,Number_of_storeys)
B=zero_matrix(RR,Number_of_storeys,Number_of_storeys)
for i in range(Number_of_storeys):
	for j in range(Number_of_storeys):
		q=Omega[i]
		r=Omega[j]
		B[i,j]=(r/q)
B=B.n(digits=4)
for i in range(Number_of_storeys):
	for j in range(Number_of_storeys):
		b=1+B[i,j]
		q=8*(0.05)^2*(b)*B[i,j]^1.5
		e=(1-B[i,j]^2)^2+4*(0.05)*B[i,j]*(b)^2
		P[i,j]=q/e
Lateral_force=zero_vector(RR,Number_of_storeys)
for i in range(Number_of_storeys):
	l=Peak_shear_force[:,i].transpose()*P*Peak_shear_force[:,i]
	Lateral_force[i]=sqrt(l[0,0])
Force=zero_vector(RR,Number_of_storeys)
for i in range(Number_of_storeys):
	if(i==Number_of_storeys-1):
		Force[i]=Lateral_force[i]
		break
	Force[i]=Lateral_force[i]-Lateral_force[i+1]
p=list()
for i in range(Number_of_storeys):
	for j in range(Number_of_storeys):
		if(j==0):
			p.append(line([(XX[j,i],Level_floor[j]),(0,0)],color=hue(0.4 + 0.6*(i/10))))
		else:
			p.append(line([(XX[j,i],Level_floor[j]),(XX[j-1,i],Level_floor[j-1])],marker='o',color=hue(0.4 + 0.6*(i/10))))
q=plot([])
for r in range(16):
	q= q+p[r]
