syms q0  
syms q1   
syms q2  
syms q3
syms w_bx
syms w_by
syms w_bz
 
q = [q0;q1;q2;q3];
matrix_n2b = quatToRotMat(q);
matrix_b2n = matrix_n2b';
acce_n = [0;0;1]; %���ٶȼ������ڵ�������ϵ�µ�ͶӰ��ע����ٶȼƵ�λΪg
acce_b = matrix_b2n*acce_n; %���ٶȼ���������������ϵ�µ�ͶӰ
acce_dif=[diff(acce_b,q0),diff(acce_b,q1),diff(acce_b,q2),diff(acce_b,q3),diff(acce_b,w_bx),diff(acce_b,w_by),diff(acce_b,w_bz)] %���ſ˱Ⱦ���
 
% ���
% acce_dif =
% [ -2*(q2),  2*(q3), -2*(q0), 2*(q1)]
% [  2*(q1),  2*(q0),  2*(q3), 2*(q2)]
% [  2*(q0), -2*(q1), -2*(q2), 2*(q3)]
