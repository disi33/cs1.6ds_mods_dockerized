FROM ubuntu:18.04
LABEL maintainer="Simon Diesenreiter"
 
ENV DEFAULTMAP gg_fy_simpsons
ENV MAXPLAYERS 10
ENV PORT 27015
ENV CLIENTPORT 27005
ENV SERVERNAME WarmItUp
ENV RCONPASS p4sswd
 
EXPOSE $PORT/udp
EXPOSE $CLIENTPORT/udp
EXPOSE $PORT
EXPOSE $CLIENTPORT
EXPOSE 1200/udp

ENV PODBOTPASS $RCONPASS
 
RUN dpkg --add-architecture i386
RUN apt-get update && apt-get -qqy install lib32gcc1 wget sudo unzip unrar
 
# script refuses to run in root, create user
RUN useradd -m csserver
RUN echo "csserver:csserver" | chpasswd
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN adduser csserver sudo
USER csserver
WORKDIR /home/csserver
 
# download SteamCmd and get the CS 1.6 dedicated server
RUN wget -qO- "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
RUN ./steamcmd.sh +login anonymous +force_install_dir ./cs16 +app_set_config "90 mod cs" +app_update 90 validate +quit; exit 0
RUN ./steamcmd.sh +login anonymous +force_install_dir ./cs16 +app_set_config "90 mod cs" +app_update 90 validate +quit; exit 0

# switch working directory to server dir
WORKDIR /home/csserver/cs16

# install Metamod
RUN mkdir -p cstrike/addons/metamod/dlls
RUN mkdir -p metamod_tmp
WORKDIR /home/csserver/cs16/metamod_tmp
RUN wget 'https://sourceforge.net/projects/metamod/files/Metamod%20Binaries/1.20/metamod-1.20-linux.tar.gz'
RUN tar -zxvf metamod-1.20-linux.tar.gz
RUN mv metamod_i386.so ../cstrike/addons/metamod/dlls/
RUN mv metamod.so ../cstrike/addons/metamod/dlls/
WORKDIR /home/csserver/cs16
RUN rm -R metamod_tmp
 
# install Podbot bots
RUN mkdir -p podbot_tmp
WORKDIR /home/csserver/cs16/podbot_tmp
RUN wget -O podbot_full_v3b21.zip 'https://gamebanana.com/dl/3277'
RUN unzip podbot_full_v3b21.zip
RUN mv podbot ../cstrike/addons
WORKDIR /home/csserver/cs16
RUN rm -R podbot_tmp
RUN echo "linux addons/podbot/podbot_mm_i386.so" >> cstrike/addons/metamod/plugins.ini
COPY liblist.gam cstrike/
RUN sed 's/pb add 100//g' ./cstrike/addons/podbot/podbot.cfg >> ./cstrike/addons/podbot/podbot.cfgtmp
RUN rm ./cstrike/addons/podbot/podbot.cfg
RUN mv ./cstrike/addons/podbot/podbot.cfgtmp ./cstrike/addons/podbot/podbot.cfg

# install AMX Mod X Base package
RUN mkdir -p amxbase_tmp
WORKDIR /home/csserver/cs16/amxbase_tmp
RUN wget 'https://www.amxmodx.org/release/amxmodx-1.8.2-base-linux.tar.gz'
RUN tar xzvf amxmodx-1.8.2-base-linux.tar.gz
RUN mkdir -p ../cstrike/addons/amxmodx
RUN cp -r ./addons/amxmodx/* ../cstrike/addons/amxmodx
WORKDIR /home/csserver/cs16
RUN rm -R amxbase_tmp

# install AMX Mod X CS package
RUN mkdir -p amxcs_tmp
WORKDIR /home/csserver/cs16/amxcs_tmp
RUN wget 'https://www.amxmodx.org/release/amxmodx-1.8.2-cstrike-linux.tar.gz'
RUN tar xzvf amxmodx-1.8.2-cstrike-linux.tar.gz
RUN cp -r ./addons/amxmodx/* ../cstrike/addons/amxmodx
WORKDIR /home/csserver/cs16
RUN rm -R amxcs_tmp

# install gungame mod
RUN wget -O gungame.rar 'https://gamebanana.com/dl/1192'
RUN unrar x gungame.rar
RUN cp -r GunGame\ AMXX\ 2.13b/GunGame\ AMXX\ 2.13b/addons/* ./cstrike/addons/
RUN cp -r GunGame\ AMXX\ 2.13b/GunGame\ AMXX\ 2.13b/sound/* ./cstrike/sound/
RUN rm -R GunGame\ AMXX\ 2.13b
RUN echo "gungame.amxx" >> cstrike/addons/amxmodx/configs/plugins.ini
# original GunGame mod website is unavailable, this version has custom configs we don't want, we need to:
# - turn off teamplay by default
# - restore original weapon order
# - turn off deathmatch
RUN sed 's/m249,awp,sg550,g3sg1,aug,sg552,m4a1,scout,ak47,famas,galil,p90,ump45,mp5navy,mac10,tmp,xm1014,m3,deagle,elite,fiveseven,p228,usp,glock18,knife/glock18,usp,p228,deagle,fiveseven,elite,m3,xm1014,tmp,mac10,mp5navy,ump45,p90,galil,famas,ak47,scout,m4a1,sg552,aug,m249,hegrenade,knife/g' cstrike/addons/amxmodx/configs/gungame.cfg >> cstrike/addons/amxmodx/configs/gungame.cfgtmp
RUN rm cstrike/addons/amxmodx/configs/gungame.cfg
RUN mv cstrike/addons/amxmodx/configs/gungame.cfgtmp cstrike/addons/amxmodx/configs/gungame.cfg
RUN sed 's/gg_teamplay 1/gg_teamplay 0/g' cstrike/addons/amxmodx/configs/gungame.cfg >> cstrike/addons/amxmodx/configs/gungame.cfgtmp
RUN rm cstrike/addons/amxmodx/configs/gungame.cfg
RUN mv cstrike/addons/amxmodx/configs/gungame.cfgtmp cstrike/addons/amxmodx/configs/gungame.cfg
RUN sed 's/gg_max_lvl 3/gg_max_lvl 0/g' cstrike/addons/amxmodx/configs/gungame.cfg >> cstrike/addons/amxmodx/configs/gungame.cfgtmp
RUN rm cstrike/addons/amxmodx/configs/gungame.cfg
RUN mv cstrike/addons/amxmodx/configs/gungame.cfgtmp cstrike/addons/amxmodx/configs/gungame.cfg
RUN sed 's/gg_warmup_timer_setting 60/gg_warmup_timer_setting 20/g' cstrike/addons/amxmodx/configs/gungame.cfg >> cstrike/addons/amxmodx/configs/gungame.cfgtmp
RUN rm cstrike/addons/amxmodx/configs/gungame.cfg
RUN mv cstrike/addons/amxmodx/configs/gungame.cfgtmp cstrike/addons/amxmodx/configs/gungame.cfg
RUN sed 's/gg_dm 1/gg_dm 0/g' cstrike/addons/amxmodx/configs/gungame.cfg >> cstrike/addons/amxmodx/configs/gungame.cfgtmp
RUN rm cstrike/addons/amxmodx/configs/gungame.cfg
RUN mv cstrike/addons/amxmodx/configs/gungame.cfgtmp cstrike/addons/amxmodx/configs/gungame.cfg

# configure AMX Mod X
RUN echo "linux addons/amxmodx/dlls/amxmodx_mm_i386.so" >> cstrike/addons/metamod/plugins.ini
RUN mkdir -p amxconfig_tmp
WORKDIR /home/csserver/cs16/amxconfig_tmp
RUN wget -O amxx_podbotmenu.amxx 'http://www.amxmodx.org/plcompiler_vb.cgi?file_id=14105'
RUN mv amxx_podbotmenu.amxx ../cstrike/addons/amxmodx/plugins
WORKDIR /home/csserver/cs16
RUN rm -R amxconfig_tmp
RUN echo "amxx_podbotmenu.amxx" >> cstrike/addons/amxmodx/configs/plugins.ini
RUN echo "\"STEAM_0:0:13868677\" \"\" \"abcdefghijklmnopqrstu\" \"ce\" ;" >> cstrike/addons/amxmodx/configs/users.ini
RUN echo "amx_addclientmenuitem \"Podbot Menu\" \"amx_pbmenu\" \"u\" \"POD-Bot mm\"" >> cstrike/addons/amxmodx/configs/custommenuitems.cfg
RUN echo "amx_addclientmenuitem \"Map Menu\" \"amx_mapmenu\" \"u\" \"POD-Bot mm\"" >> cstrike/addons/amxmodx/configs/custommenuitems.cfg
RUN echo "\"Podbot menu\" \"amx_pbmenu\" \"b\" \"u\"" >> cstrike/addons/amxmodx/configs/cmds.ini
RUN echo "\"Map menu\" \"amx_mapmenu\" \"b\" \"u\"" >> cstrike/addons/amxmodx/configs/cmds.ini
RUN sed 's/;fakemeta/fakemeta/g' cstrike/addons/amxmodx/configs/modules.ini >> cstrike/addons/amxmodx/configs/modules.initmp
RUN rm cstrike/addons/amxmodx/configs/modules.ini
RUN mv cstrike/addons/amxmodx/configs/modules.initmp cstrike/addons/amxmodx/configs/modules.ini
RUN sed 's/;hamsandwich/hamsandwich/g' cstrike/addons/amxmodx/configs/modules.ini >> cstrike/addons/amxmodx/configs/modules.initmp
RUN rm cstrike/addons/amxmodx/configs/modules.ini
RUN mv cstrike/addons/amxmodx/configs/modules.initmp cstrike/addons/amxmodx/configs/modules.ini

# setup maps, mapcycle and pluginconfigs per map
ADD maps/gfx/env/* ./cstrike/gfx/env/
ADD maps/maps/* ./cstrike/maps/
ADD maps/models/* ./cstrike/models/
ADD maps/overviews/* ./cstrike/overviews/
ADD maps/sprites/* ./cstrike/sprites/
ADD maps/sound/ambience/* ./cstrike/sound/ambience/
ADD maps/wads/* ./cstrike/
RUN rm ./cstrike/addons/amxmodx/configs/maps.ini
ADD maps/maps.ini ./cstrike/addons/amxmodx/configs/
RUN mkdir ./cstrike/addons/amxmodx/configs/maps
ADD maps/mapconfig/* ./cstrike/addons/amxmodx/configs/maps/
ADD maps/waypoints/* ./cstrike/addons/podbot/wptdefault/

# Start the server
ADD cfg/* ./
RUN sed 's/<SERVER_NAME>/$SERVERNAME/g' server.cfg >> server.cfgtmp
RUN rm server.cfg
RUN mv server.cfgtmp server.cfg
RUN sed 's/<RCON_PASSWD>/$RCONPASS/g' server.cfg >> server.cfgtmp
RUN rm server.cfg
RUN mv server.cfgtmp server.cfg
RUN sed 's/"pb menu"/"amx_cmdmenu"/g' ./cstrike/addons/podbot/podbot.cfg >> ./cstrike/addons/podbot/podbot.cfgtmp
RUN rm ./cstrike/addons/podbot/podbot.cfg
RUN mv ./cstrike/addons/podbot/podbot.cfgtmp ./cstrike/addons/podbot/podbot.cfg

ENTRYPOINT ./hlds_run -game cstrike -strictportbind -ip 0.0.0.0 -port $PORT +clientport $CLIENTPORT  +map $DEFAULTMAP -maxplayers $MAXPLAYERS +hostname "$SERVERNAME"