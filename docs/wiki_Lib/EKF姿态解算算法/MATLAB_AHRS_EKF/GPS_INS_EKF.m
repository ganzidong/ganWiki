clear
close all
%2022年3月30日
%EKF的动态特性优于互补滤波
%EKF增加加速过程修正环节动态特性优于不加修正
tick = 0;
file = 'DZ311_FlyData1.mat';
%ENU坐标系
rad2deg = 180/pi;

%导入测试数据
load(file);
data_ax = data(:,fcu.imu.ax);
data_ay = data(:,fcu.imu.ay);
data_az = data(:,fcu.imu.az);

data_gx = data(:,fcu.imu.gx);
data_gy = data(:,fcu.imu.gy);
data_gz = data(:,fcu.imu.gz);

data_mx = data(:,fcu.mag.mx);
data_my = data(:,fcu.mag.my);
data_mz = data(:,fcu.mag.mz);


data_mag_ang_z = data(:,fcu.mag.ang_z);

data_num = length(data_ax);
time = zeros(1,data_num);

data_init_len = 10; %用于初始化的开始数据数量

dt = 0.05; %20Hz

%定义变量记录姿态角
roll = zeros(1,data_num);
pitch = zeros(1,data_num);
yaw = zeros(1,data_num);

acc_e = zeros(1,data_num);
acc_n = zeros(1,data_num);
acc_u = zeros(1,data_num);

% acc_bias_e = zeros(1,data_num);
% 
% vel_bias_e = zeros(1,data_num);

vel_e = zeros(1,data_num);
vel_n = zeros(1,data_num);
vel_u = zeros(1,data_num);


pos_e = zeros(1,data_num);
pos_n = zeros(1,data_num);
pos_u = zeros(1,data_num);

%定义状态变量
q=[1,0,0,0];  %四元数
g_bias = [0,0,0]; %陀螺偏差
X = [q,g_bias]'; %状态变量

%取前十个值作为初始化值
%定义测量值
gx = 0;
gy = 0;
gz = 0;

ax = sum(data_ax(1:data_init_len))/data_init_len;
ay = sum(data_ay(1:data_init_len))/data_init_len;
az = sum(data_az(1:data_init_len))/data_init_len;  %单位：g

acc = [ax,ay,az];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%初始化欧拉角
acc = acc./norm(acc); %对加速度进行归一化处理

roll(1) = asin(ay/norm(acc));
pitch(1) = atan2(-ax,az);
yaw(1) = sum(data_mag_ang_z(5:data_init_len))/ 5;

for i=2:data_init_len
    roll(i) = roll(1);
    pitch(i) = pitch(1);
    yaw(i) = 0;%yaw(1);
end

%初始化四元数
q = EularTransToQuad(roll(1),pitch(1),yaw(1)); 
X = [q,g_bias]'; %初始化状态变量
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%初始化噪声
acc_var = 1e-1 * ones(1,3); %加速计测量噪声方差
Q_bn = 1e-8 * ones(1,3);%陀螺偏置过程噪声方差
gyro_var = 1e-6 * ones(1,3); %陀螺过程噪声方差

mag_yaw_k = 1e-2; %磁力计偏航角的置信度

%计算四元数过程噪声方差
Q_qn = ones(1,4);%四元数过程噪声方差 随四元数变化而变化的
Q_qn(1) = (dt/2)^2 *  gyro_var(1) * q(2)^2 + gyro_var(2) * q(3)^2+gyro_var(3) * q(4)^2;
Q_qn(2) = (dt/2)^2 *  gyro_var(1) * q(1)^2 + gyro_var(3) * q(3)^2+gyro_var(2) * q(4)^2;
Q_qn(3) = (dt/2)^2 *  gyro_var(2) * q(1)^2 + gyro_var(3) * q(2)^2+gyro_var(1) * q(4)^2;
Q_qn(4) = (dt/2)^2 *  gyro_var(3) * q(1)^2 + gyro_var(2) * q(2)^2+gyro_var(1) * q(3)^2;
Q = diag([Q_qn,Q_bn]); %过程噪声协方差矩阵
R = diag(acc_var); %测量噪声协方差矩阵
P = eye(7); %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%进入迭代
for i = data_init_len:data_num
    time(i) = time(i-1) + dt;
    gx = data_gx(i);
    gy = data_gy(i);
    gz = data_gz(i);

    ax = data_ax(i);
    ay = data_ay(i);
    az = data_az(i);
    
    mx = data_mx(i);
    my = data_my(i);
    mz = data_mz(i);
    
    acc = [ax,ay,az];
    
    %增加加速状态加速度修正环节
    R_b2n = quatToRotMat(q);
    acc_enu = R_b2n*acc';
    acc_err = [0 0 9.8]' - acc_enu; %获得导航系下加速度与重力加速度的偏差
    acc = acc - (R_b2n' * acc_err)'; %机体系下减去偏差
   
    
    
    %计算状态转移矩阵
    wx = gx - g_bias(1); %减去偏差
    wy = gy - g_bias(2);
    wz = gz - g_bias(3);
    %四元数部分
    ht = dt/2;
    Akq =        [0, -wx*ht, -wy*ht,-wz*ht;
                 wx*ht, 0 ,  wz*ht,-wy*ht;
                 wy*ht, -wz*ht, 0, wx*ht;
                 wz*ht, wy*ht,  -wx*ht, 0]  + eye(4);
    Akgb = diag(ones(1,3));  %陀螺偏差部分

    A = [Akq,zeros(4,3);zeros(3,4),Akgb]; %获得完整的状态转移矩阵
    X_ = A*X; %状态计算预测值
    q_ = X_(1:4);
    %计算状态转移矩阵的雅克比矩阵
    G =  [ 0, -wx*ht, -wy*ht,-wz*ht,q(2)*ht,q(3)*ht,q(4)*ht;
           wx*ht, 0 ,  wz*ht,-wy*ht, -q(1)*ht,q(4)*ht,-q(3)*ht;
           wy*ht, -wz*ht, 0, wx*ht, -q(4)*ht,-q(1)*ht,q(2)*ht;
           wz*ht, wy*ht,  -wx*ht, 0, q(3)*ht,-q(2)*ht,-q(1)*ht;
           0,0,0,0,0,0,0;
           0,0,0,0,0,0,0;
           0,0,0,0,0,0,0]  + eye(7);

    %计算先验过程预测值协方差矩阵
    Q_qn(1) = (dt/2)^2 *  gyro_var(1) * q(2)^2 + gyro_var(2) * q(3)^2+gyro_var(3) * q(4)^2;
    Q_qn(2) = (dt/2)^2 *  gyro_var(1) * q(1)^2 + gyro_var(3) * q(3)^2+gyro_var(2) * q(4)^2;
    Q_qn(3) = (dt/2)^2 *  gyro_var(2) * q(1)^2 + gyro_var(3) * q(2)^2+gyro_var(1) * q(4)^2;
    Q_qn(4) = (dt/2)^2 *  gyro_var(3) * q(1)^2 + gyro_var(2) * q(2)^2+gyro_var(1) * q(3)^2;
    Q = diag([Q_qn,Q_bn]); %过程噪声协方差矩阵

    P_ = G*P*G' + Q;
    
%注意测量方程中用的状态变量是由系统方程预测后的k时刻的值

    
    %计算测量方程的雅克比矩阵
    H =[-2*q_(3),2*q_(4),-2*q_(1),2*q_(2),0,0,0;
        2*q_(2),2*q_(1),2*q_(4),2*q_(3),0,0,0;
        2*q_(1),-2*q_(2),-2*q_(3),2*q_(4),0,0,0];

    %计算卡尔曼增益
    K = (P_*H')/(H*P_*H'+R);

    %更新状态估计值
    Z = acc'./norm(acc); %归一化处理
    
    h_ = [2*q_(2)*q_(4) - 2*q_(1)*q_(3);
        2*q_(3)*q_(4) + 2*q_(1)*q_(2);
        (q_(1)^2 -q_(2)^2 -q_(3)^2+q_(4)^2)];%由系统方程预估的测量值
    
    X = X_ + K*(Z - h_);
    %更新四元数并归一化
    q = X(1:4);
    q = q./norm(q);
    X(1) = q(1); %归一化更新状态值
    X(2) = q(2);
    X(3) = q(3);
    X(4) = q(4);
    %更新协方差矩阵P
    P = (eye(7) - K*H)*P_;

    %将四元数转化为欧拉角
    roll(i) =atan2(2*(q(1)*q(2) + q(3)*q(4)),1-2*(q(2)^2+q(3)^2));
    pitch(i) = asin(2*(q(1)*q(3) - q(4)*q(2)));
    yaw(i) = atan2(2*(q(1)*q(4) +q(2)*q(3)),1-2*(q(3)^2+q(4)^2));
    
    %使用磁力计更新偏航角
    hx = mx*cos( pitch(i)) + mz *sin( pitch(i));
    hy = mx*sin( pitch(i))*sin(roll(i)) + my*cos(roll(i))-mz*cos( pitch(i))*sin(roll(i));

% 	hx = mx * (1.0 - (2*(q(2)*q(4)-q(1)*q(3))^2) - (2*(q(2)*q(4)-q(1)*q(3)))) * (my * (2*(q(3)*q(4) + q(1)*q(2))) + mz * (q(1)^2-q(2)^2 - q(3)^2 + q(4)^2));
% 	hy = my *( q(1)^2-q(2)^2 - q(3)^2 + q(4)^2) - mz * (2*(q(3)*q(4) + q(1)*q(2)));
     
    mag_yaw = wrap(pi/2 - atan2(hy,hx),-pi,pi);  %坐标系变换，旋转方向和东向校正
    %注意这里为修正磁偏角
    
    yaw(i) = yaw(i) + mag_yaw_k * wrap((mag_yaw - yaw(i)),-pi,pi);
    
    %更新修正偏航角后的四元数
    q = EularTransToQuad(roll(i),pitch(i),yaw(i)); 
    X(1) = q(1); 
    X(2) = q(2);
    X(3) = q(3);
    X(4) = q(4);

    if(yaw(i) < 0) 
        yaw(i) =yaw(i)+2*pi;
    end
    
    %GPS位置融合，由于都是线性系统，所以直接分步计算，以下通过加权 和P控制方法
   
  % R_b2n = quatToRotMat(EularTransToQuad(data(i,fcu.ang_x),data(i,fcu.ang_y),data(i,fcu.ang_z)));
    R_b2n = quatToRotMat(q);
    acc_enu = R_b2n*acc';
    acc_e(i) = acc_enu(1);
    acc_n(i) = acc_enu(2);
    acc_u(i) = acc_enu(3) - 9.8;
    
    %更新加速度偏差，GPS延迟 50ms，默认偏差不是突变的,GPS数据更新频率5Hz 200ms
    
%     acc_gps_e = (data(i,fcu.gps.vel_n) - (data(i-4,fcu.gps.vel_n)))/0.2; %GPS差分得到的加速度
    acc_bias_e = 1.5*(data(i,fcu.gps.vel_n) - vel_e(i-2))  + 0.0*(data(i,fcu.gps.pos_e) - pos_e(i-4)); %考虑更新延迟
    acc_bias_n = 1.5*(data(i,fcu.gps.vel_e) - vel_n(i-2))  + 0.0*(data(i,fcu.gps.pos_n) - pos_n(i-4)); %考虑更新延迟
    acc_bias_u = 1.5*(data(i,fcu.gps.vel_u) - vel_u(i-2))  + 0.0*(data(i,fcu.gps.pos_u) - pos_u(i-4)); %考虑更新延迟
    
    vel_e(i) = vel_e(i-1) + (acc_e(i) + acc_bias_e) *dt;
    vel_n(i) = vel_n(i-1) + (acc_n(i) + acc_bias_n) *dt;
    vel_u(i) = vel_u(i-1) + (acc_u(i) + acc_bias_u) *dt;
    
    %vel_e(i) = vel_e(i) + 0.1 *(data(i,fcu.gps.vel_n) - vel_e(i));
    
    
    vel_bias_e = 2*(data(i,fcu.gps.pos_e) - pos_e(i-2));
    vel_bias_n = 2*(data(i,fcu.gps.pos_n) - pos_n(i-2));
    vel_bias_u = 2*(data(i,fcu.gps.pos_u) - pos_u(i-2));
    
    pos_e(i) = pos_e(i-1) + (vel_e(i) + vel_bias_e)*dt;
    pos_n(i) = pos_n(i-1) + (vel_n(i) + vel_bias_n)*dt;
    pos_u(i) = pos_u(i-1) + (vel_u(i) + vel_bias_u)*dt;
    
    pos_e(i) = pos_e(i) + 0.0 *(data(i,fcu.gps.pos_e) - pos_e(i));
   
     
end

figure
hold on
grid on

% plot(time,roll*rad2deg,'r','DisplayName','EKF_Roll','linewidth',2);
% plot(time,data(:,fcu.ang_x)*rad2deg,'b','DisplayName','FCU_Roll');
% plot(time,pitch*rad2deg,'g','DisplayName','EKF_Pitch','linewidth',2);
% plot(time,data(:,fcu.ang_y)*rad2deg,'y','DisplayName','FCU_Pitch');
% 
% plot(time,yaw*rad2deg,'c','DisplayName','EKF_Yaw','linewidth',2);
% plot(time,data(:,fcu.ang_z)*rad2deg,'m','DisplayName','FCU_Yaw');
% plot(time,data(:,fcu.mag.ang_z)*rad2deg,'k','DisplayName','Mag_Yaw');

% plot(time,data(:,fcu.acc_now_e),'r','DisplayName','acc_now_e','linewidth',2);
% plot(time,data(:,fcu.acc_now_n),'g','DisplayName','acc_now_e','linewidth',2);
%  plot(time,acc_e*0.5,'b','DisplayName','acc_now_e','linewidth',2);
% plot(time,acc_n,'k','DisplayName','acc_now_e','linewidth',2);

plot(time,data(:,fcu.vel_now_e),'r','DisplayName','fcu_vel_now_e','linewidth',2);
plot(time,data(:,fcu.gps.vel_n),'k','DisplayName','gps_vel_now_e','linewidth',2);
plot(time,vel_e,'b','DisplayName','vel_e','linewidth',2);

plot(time,data(:,fcu.pos_now_e),'r','DisplayName','fcu_pos_now_e','linewidth',2);
plot(time,data(:,fcu.gps.pos_e),'k','DisplayName','gps_pos_now_e','linewidth',2);
plot(time,pos_e,'b','DisplayName','pos_e','linewidth',2);

plot(time,data(:,fcu.vel_now_n),'r','DisplayName','fcu_vel_now_n','linewidth',2);
plot(time,data(:,fcu.gps.vel_e),'k','DisplayName','gps_vel_now_n','linewidth',2);
plot(time,vel_n,'b','DisplayName','vel_n','linewidth',2);

plot(time,data(:,fcu.pos_now_n),'r','DisplayName','fcu_pos_now_n','linewidth',2);
plot(time,data(:,fcu.gps.pos_n),'k','DisplayName','gps_pos_now_n','linewidth',2);
plot(time,pos_n,'b','DisplayName','pos_n','linewidth',2);


plot(time,data(:,fcu.vel_now_u),'r','DisplayName','fcu_vel_now_u','linewidth',2);
plot(time,data(:,fcu.gps.vel_u),'k','DisplayName','gps_vel_now_u','linewidth',2);
plot(time,vel_u,'b','DisplayName','vel_u','linewidth',2);

plot(time,data(:,fcu.pos_now_u),'r','DisplayName','fcu_pos_now_u','linewidth',2);
plot(time,data(:,fcu.gps.pos_u),'k','DisplayName','gps_pos_now_u','linewidth',2);
plot(time,pos_u,'b','DisplayName','pos_u','linewidth',2);


figure 
hold on
grid on
plot3(pos_e,pos_n,pos_u,'g','DisplayName','pos','linewidth',2);
plot3(data(:,fcu.pos_now_e),data(:,fcu.pos_now_n),data(:,fcu.pos_now_u),'r','DisplayName','fcu_pos','linewidth',2);
plot3(data(:,fcu.gps.pos_e),data(:,fcu.gps.pos_n),data(:,fcu.gps.pos_u),'b','DisplayName','gps_pos','linewidth',2);