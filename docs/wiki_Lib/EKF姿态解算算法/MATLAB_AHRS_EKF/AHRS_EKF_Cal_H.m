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
acce_n = [0;0;1]; %加速度计数据在导航坐标系下的投影，注意加速度计单位为g
acce_b = matrix_b2n*acce_n; %加速度计数据在载体坐标系下的投影
acce_dif=[diff(acce_b,q0),diff(acce_b,q1),diff(acce_b,q2),diff(acce_b,q3),diff(acce_b,w_bx),diff(acce_b,w_by),diff(acce_b,w_bz)] %求雅克比矩阵
 
% 结果
% acce_dif =
% [ -2*(q2),  2*(q3), -2*(q0), 2*(q1)]
% [  2*(q1),  2*(q0),  2*(q3), 2*(q2)]
% [  2*(q0), -2*(q1), -2*(q2), 2*(q3)]
