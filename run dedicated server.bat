:restart
start /wait omohaaded.x86_64.exe +set dedicated 2 +set sv_maxclients 16 +set net_port 12203 +exec server.cfg +set developer 2 +set logfile 2
goto restart
