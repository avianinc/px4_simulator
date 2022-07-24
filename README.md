# px4_simulator
 PX4 SITL simulator with QGroundControl in noVNC container
 
1) Login to Guacamole:
username: user
password: password

2) Open the VNC server from Guac...

3) To run the simulator:
- Open a terminal
- cd into /home/user/PX4-Autopilot
- make px4_sitl gazebo # this take a while.. so get a beer
- Open a second terminal
- cd /home/user
- ./QGroundControl.AppImage --appimage-extract-and-run

Have fun...
