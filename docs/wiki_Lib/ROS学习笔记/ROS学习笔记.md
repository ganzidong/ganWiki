### ROS学习笔记

#### ROS2系统安装
[参考教程](https://mp.weixin.qq.com/s?__biz=MzU1NjEwMTY0Mw==&mid=2247555708&idx=2&sn=55b2fbc07a213d22897026f6fc484ab9&chksm=fbc86318ccbfea0e12e6f9a5e04b17cc9ad63b62965bc3ef8e99aa24ece0913e1450b39d8bcc&scene=27)

系统 ：ubuntu22.04

安装步骤
1. 设置编码
``` sh
sudo apt update && sudo apt install locales
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8
```
2. 添加源
```sh
$ sudo apt update && sudo apt install curl gnupg lsb-release 
$ sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg 
$ echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(source /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
```
如遇报错“Failed to connect to raw.githubusercontent.com”

可参考：https://www.guyuehome.com/37844

3. 安装ROS2
```sh
$ sudo apt update
$ sudo apt upgrade
$ sudo apt install ros-humble-desktop
```

4. 设置环境变量
```sh
$ source /opt/ros/humble/setup.bash
$ echo " source /opt/ros/humble/setup.bash" >> ~/.bashrc
```
至此，ROS2就已经在系统中安装好了。

![照片测试](https://gitee.com/ganzidong/gan-wiki/blob/dev/docs/img/gtee_01.png)