#Wait for code
d=

cd $d
./srcds_run -console -game cstrike -maxplayers 10 -port 27015 +map de_dust2
systemctl restart CSS
exit
