enu_acc = [0.000139, -4.69, 11.09]';
q = [0.98, 0.1968, -5.53e-8, 4.42e-9];

R = quatToRotMat(q);

acc = R * enu_acc

roll =atan2(2*(q(1)*q(2) + q(3)*q(4)),1-2*(q(2)^2+q(3)^2))
pitch = asin(2*(q(1)*q(3) - q(4)*q(2)));
yaw = atan2(2*(q(1)*q(4) +q(2)*q(3)),1-2*(q(3)^2+q(4)^2));

asin(acc(2)/norm(acc))