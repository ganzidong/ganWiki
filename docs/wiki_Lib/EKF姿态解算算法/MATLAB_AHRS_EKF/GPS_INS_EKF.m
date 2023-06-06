clear
close all
%2022��3��30��
%EKF�Ķ�̬�������ڻ����˲�
%EKF���Ӽ��ٹ����������ڶ�̬�������ڲ�������
tick = 0;
file = 'DZ311_FlyData1.mat';
%ENU����ϵ
rad2deg = 180/pi;

%�����������
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

data_init_len = 10; %���ڳ�ʼ���Ŀ�ʼ��������

dt = 0.05; %20Hz

%���������¼��̬��
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

%����״̬����
q=[1,0,0,0];  %��Ԫ��
g_bias = [0,0,0]; %����ƫ��
X = [q,g_bias]'; %״̬����

%ȡǰʮ��ֵ��Ϊ��ʼ��ֵ
%�������ֵ
gx = 0;
gy = 0;
gz = 0;

ax = sum(data_ax(1:data_init_len))/data_init_len;
ay = sum(data_ay(1:data_init_len))/data_init_len;
az = sum(data_az(1:data_init_len))/data_init_len;  %��λ��g

acc = [ax,ay,az];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%��ʼ��ŷ����
acc = acc./norm(acc); %�Լ��ٶȽ��й�һ������

roll(1) = asin(ay/norm(acc));
pitch(1) = atan2(-ax,az);
yaw(1) = sum(data_mag_ang_z(5:data_init_len))/ 5;

for i=2:data_init_len
    roll(i) = roll(1);
    pitch(i) = pitch(1);
    yaw(i) = 0;%yaw(1);
end

%��ʼ����Ԫ��
q = EularTransToQuad(roll(1),pitch(1),yaw(1)); 
X = [q,g_bias]'; %��ʼ��״̬����
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%��ʼ������
acc_var = 1e-1 * ones(1,3); %���ټƲ�����������
Q_bn = 1e-8 * ones(1,3);%����ƫ�ù�����������
gyro_var = 1e-6 * ones(1,3); %���ݹ�����������

mag_yaw_k = 1e-2; %������ƫ���ǵ����Ŷ�

%������Ԫ��������������
Q_qn = ones(1,4);%��Ԫ�������������� ����Ԫ���仯���仯��
Q_qn(1) = (dt/2)^2 *  gyro_var(1) * q(2)^2 + gyro_var(2) * q(3)^2+gyro_var(3) * q(4)^2;
Q_qn(2) = (dt/2)^2 *  gyro_var(1) * q(1)^2 + gyro_var(3) * q(3)^2+gyro_var(2) * q(4)^2;
Q_qn(3) = (dt/2)^2 *  gyro_var(2) * q(1)^2 + gyro_var(3) * q(2)^2+gyro_var(1) * q(4)^2;
Q_qn(4) = (dt/2)^2 *  gyro_var(3) * q(1)^2 + gyro_var(2) * q(2)^2+gyro_var(1) * q(3)^2;
Q = diag([Q_qn,Q_bn]); %��������Э�������
R = diag(acc_var); %��������Э�������
P = eye(7); %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%�������
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
    
    %���Ӽ���״̬���ٶ���������
    R_b2n = quatToRotMat(q);
    acc_enu = R_b2n*acc';
    acc_err = [0 0 9.8]' - acc_enu; %��õ���ϵ�¼��ٶ����������ٶȵ�ƫ��
    acc = acc - (R_b2n' * acc_err)'; %����ϵ�¼�ȥƫ��
   
    
    
    %����״̬ת�ƾ���
    wx = gx - g_bias(1); %��ȥƫ��
    wy = gy - g_bias(2);
    wz = gz - g_bias(3);
    %��Ԫ������
    ht = dt/2;
    Akq =        [0, -wx*ht, -wy*ht,-wz*ht;
                 wx*ht, 0 ,  wz*ht,-wy*ht;
                 wy*ht, -wz*ht, 0, wx*ht;
                 wz*ht, wy*ht,  -wx*ht, 0]  + eye(4);
    Akgb = diag(ones(1,3));  %����ƫ���

    A = [Akq,zeros(4,3);zeros(3,4),Akgb]; %���������״̬ת�ƾ���
    X_ = A*X; %״̬����Ԥ��ֵ
    q_ = X_(1:4);
    %����״̬ת�ƾ�����ſ˱Ⱦ���
    G =  [ 0, -wx*ht, -wy*ht,-wz*ht,q(2)*ht,q(3)*ht,q(4)*ht;
           wx*ht, 0 ,  wz*ht,-wy*ht, -q(1)*ht,q(4)*ht,-q(3)*ht;
           wy*ht, -wz*ht, 0, wx*ht, -q(4)*ht,-q(1)*ht,q(2)*ht;
           wz*ht, wy*ht,  -wx*ht, 0, q(3)*ht,-q(2)*ht,-q(1)*ht;
           0,0,0,0,0,0,0;
           0,0,0,0,0,0,0;
           0,0,0,0,0,0,0]  + eye(7);

    %�����������Ԥ��ֵЭ�������
    Q_qn(1) = (dt/2)^2 *  gyro_var(1) * q(2)^2 + gyro_var(2) * q(3)^2+gyro_var(3) * q(4)^2;
    Q_qn(2) = (dt/2)^2 *  gyro_var(1) * q(1)^2 + gyro_var(3) * q(3)^2+gyro_var(2) * q(4)^2;
    Q_qn(3) = (dt/2)^2 *  gyro_var(2) * q(1)^2 + gyro_var(3) * q(2)^2+gyro_var(1) * q(4)^2;
    Q_qn(4) = (dt/2)^2 *  gyro_var(3) * q(1)^2 + gyro_var(2) * q(2)^2+gyro_var(1) * q(3)^2;
    Q = diag([Q_qn,Q_bn]); %��������Э�������

    P_ = G*P*G' + Q;
    
%ע������������õ�״̬��������ϵͳ����Ԥ����kʱ�̵�ֵ

    
    %����������̵��ſ˱Ⱦ���
    H =[-2*q_(3),2*q_(4),-2*q_(1),2*q_(2),0,0,0;
        2*q_(2),2*q_(1),2*q_(4),2*q_(3),0,0,0;
        2*q_(1),-2*q_(2),-2*q_(3),2*q_(4),0,0,0];

    %���㿨��������
    K = (P_*H')/(H*P_*H'+R);

    %����״̬����ֵ
    Z = acc'./norm(acc); %��һ������
    
    h_ = [2*q_(2)*q_(4) - 2*q_(1)*q_(3);
        2*q_(3)*q_(4) + 2*q_(1)*q_(2);
        (q_(1)^2 -q_(2)^2 -q_(3)^2+q_(4)^2)];%��ϵͳ����Ԥ���Ĳ���ֵ
    
    X = X_ + K*(Z - h_);
    %������Ԫ������һ��
    q = X(1:4);
    q = q./norm(q);
    X(1) = q(1); %��һ������״ֵ̬
    X(2) = q(2);
    X(3) = q(3);
    X(4) = q(4);
    %����Э�������P
    P = (eye(7) - K*H)*P_;

    %����Ԫ��ת��Ϊŷ����
    roll(i) =atan2(2*(q(1)*q(2) + q(3)*q(4)),1-2*(q(2)^2+q(3)^2));
    pitch(i) = asin(2*(q(1)*q(3) - q(4)*q(2)));
    yaw(i) = atan2(2*(q(1)*q(4) +q(2)*q(3)),1-2*(q(3)^2+q(4)^2));
    
    %ʹ�ô����Ƹ���ƫ����
    hx = mx*cos( pitch(i)) + mz *sin( pitch(i));
    hy = mx*sin( pitch(i))*sin(roll(i)) + my*cos(roll(i))-mz*cos( pitch(i))*sin(roll(i));

% 	hx = mx * (1.0 - (2*(q(2)*q(4)-q(1)*q(3))^2) - (2*(q(2)*q(4)-q(1)*q(3)))) * (my * (2*(q(3)*q(4) + q(1)*q(2))) + mz * (q(1)^2-q(2)^2 - q(3)^2 + q(4)^2));
% 	hy = my *( q(1)^2-q(2)^2 - q(3)^2 + q(4)^2) - mz * (2*(q(3)*q(4) + q(1)*q(2)));
     
    mag_yaw = wrap(pi/2 - atan2(hy,hx),-pi,pi);  %����ϵ�任����ת����Ͷ���У��
    %ע������Ϊ������ƫ��
    
    yaw(i) = yaw(i) + mag_yaw_k * wrap((mag_yaw - yaw(i)),-pi,pi);
    
    %��������ƫ���Ǻ����Ԫ��
    q = EularTransToQuad(roll(i),pitch(i),yaw(i)); 
    X(1) = q(1); 
    X(2) = q(2);
    X(3) = q(3);
    X(4) = q(4);

    if(yaw(i) < 0) 
        yaw(i) =yaw(i)+2*pi;
    end
    
    %GPSλ���ںϣ����ڶ�������ϵͳ������ֱ�ӷֲ����㣬����ͨ����Ȩ ��P���Ʒ���
   
  % R_b2n = quatToRotMat(EularTransToQuad(data(i,fcu.ang_x),data(i,fcu.ang_y),data(i,fcu.ang_z)));
    R_b2n = quatToRotMat(q);
    acc_enu = R_b2n*acc';
    acc_e(i) = acc_enu(1);
    acc_n(i) = acc_enu(2);
    acc_u(i) = acc_enu(3) - 9.8;
    
    %���¼��ٶ�ƫ�GPS�ӳ� 50ms��Ĭ��ƫ���ͻ���,GPS���ݸ���Ƶ��5Hz 200ms
    
%     acc_gps_e = (data(i,fcu.gps.vel_n) - (data(i-4,fcu.gps.vel_n)))/0.2; %GPS��ֵõ��ļ��ٶ�
    acc_bias_e = 1.5*(data(i,fcu.gps.vel_n) - vel_e(i-2))  + 0.0*(data(i,fcu.gps.pos_e) - pos_e(i-4)); %���Ǹ����ӳ�
    acc_bias_n = 1.5*(data(i,fcu.gps.vel_e) - vel_n(i-2))  + 0.0*(data(i,fcu.gps.pos_n) - pos_n(i-4)); %���Ǹ����ӳ�
    acc_bias_u = 1.5*(data(i,fcu.gps.vel_u) - vel_u(i-2))  + 0.0*(data(i,fcu.gps.pos_u) - pos_u(i-4)); %���Ǹ����ӳ�
    
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