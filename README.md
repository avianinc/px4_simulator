# px4_simulator
 PX4 SITL simulator with QGroundControl in noVNC container
 
1) Login to Guacamole:
username: user
password: password

2) Open the VNC server from Guac...

3) To run the simulator:
a. Open a terminal
b. cd into /home/user/PX4-Autopilot
c. make px4_sitl gazebo # this take a while.. so get a beer
d. Open a second terminal
e. cd /home/user
f. ./QGroundControl.AppImage --appimage-extract-and-run

Have fun...
