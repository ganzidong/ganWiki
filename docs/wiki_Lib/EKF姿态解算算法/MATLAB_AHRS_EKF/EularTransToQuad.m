function [q] = EularTransToQuad(x,y,z)
%EULARTRANSQUAD ŷ����ת��Ԫ��
%   ��λ����
q0 = cos(x/2)*cos(y/2)*cos(z/2) + sin(x/2)*sin(y/2)*sin(z/2);
q1 = sin(x/2)*cos(y/2)*cos(z/2) - cos(x/2)*sin(y/2)*sin(z/2);
q2 = cos(x/2)*sin(y/2)*cos(z/2) + sin(x/2)*cos(y/2)*sin(z/2);
q3 = cos(x/2)*cos(y/2)*sin(z/2) - sin(x/2)*sin(y/2)*cos(z/2);

%����Ԫ�����й�һ��
qn =sqrt(q0^2 + q1^2+q2^2+q3^2);

q0 = q0 /qn;
q1 = q1 /qn;
q2 = q2 /qn;
q3 = q3 /qn;

q = [q0,q1,q2,q3];
end

