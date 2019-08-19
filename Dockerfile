FROM ubuntu:18.04
LABEL maintainer="Simon Diesenreiter"
 
ENV DEFAULTMAP de_dust2
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
RUN apt-get update && apt-get -qqy install lib32gcc1 wget sudo unzip
 
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

# configure AMX Mod X
RUN echo "linux addons/amxmodx/dlls/amxmodx_mm_i386.so" >> cstrike/addons/metamod/plugins.ini
RUN mkdir -p amxconfig_tmp
WORKDIR /home/csserver/cs16/amxconfig_tmp
RUN wget -O amxx_podbotmenu.amxx 'http://www.amxmodx.org/plcompiler_vb.cgi?file_id=14105'
RUN mv amxx_podbotmenu.amxx ../cstrike/addons/amxmodx/plugins
WORKDIR /home/csserver/cs16
RUN rm -R amxconfig_tmp
RUN echo "amxx_podbotmenu.amxx" >> cstrike/addons/amxmodx/configs/plugins.ini
RUN echo "\"STEAM_1:0:13868677\" \"\" \"abcdefghijklmnopqrstu\" \"ce\" ;" >> cstrike/addons/amxmodx/configs/users.ini
RUN echo "amx_addclientmenuitem \"Podbot Menu\" \"amx_pbmenu\" \"cu\" \"podbotmenu\"" >> cstrike/addons/amxmodx/configs/custommenuitems.cfg

# Start the server
ADD cfg/* ./
RUN sed 's/<SERVER_NAME>/$SERVERNAME/g' server.cfg
RUN sed 's/<RCON_PASSWD>/$RCONPASS/g' server.cfg
RUN sed 's/"your_password"/"$PODBOTPASS"/g' ./cstrike/addons/podbot/podbot.cfg >> ./cstrike/addons/podbot/podbot.cfgtmp
RUN rm ./cstrike/addons/podbot/podbot.cfg
RUN mv ./cstrike/addons/podbot/podbot.cfgtmp ./cstrike/addons/podbot/podbot.cfg
RUN sed 's/"pb menu"/"amx_menu"/g' ./cstrike/addons/podbot/podbot.cfg >> ./cstrike/addons/podbot/podbot.cfgtmp
RUN rm ./cstrike/addons/podbot/podbot.cfg
RUN mv ./cstrike/addons/podbot/podbot.cfgtmp ./cstrike/addons/podbot/podbot.cfg
RUN sed 's/amx_password_field "_pw"/amx_password_field "_amxpw"/g' ./cstrike/addons/amxmodx/config/amxx.cfg


ENTRYPOINT ./hlds_run -game cstrike -strictportbind -ip 0.0.0.0 -port $PORT +clientport $CLIENTPORT  +map $DEFAULTMAP -maxplayers $MAXPLAYERS +hostname "$SERVERNAME"