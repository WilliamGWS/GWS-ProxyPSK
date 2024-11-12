#!/bin/bash
#prueba

# VARIABLES DE CONFIGURACIÓN
#VARIABLE PARA LA FUNCION LOG SE USO $HOME PARA QUE CUALQUIER USUARIO QUE EJECUTE EL ARCHIVO CREE UN ARCHIVO LOG EN SU DIRECTORIO Y NO TENER PROBLEMAS DE PERMISOS
LOG_FILE="/$HOME/script_logPSK.txt" 

#************** DATOS ZABBIX PROXY *******************
#VALIDACION Y CONEXION AL SERVER zabbix
ZABBIX_SERVER_IP="zabbix01.nubecentral.com:10051;zabbix02.nubecentral.com:10051"

#UBICACION DE ARCHIVO DE CIFRADO
ZABBIX_PROXY_PSK="/opt/encrypted.key"


set -e  # Activar el modo de detener el script en caso de error

# Banners y funciones de mensajes
BannerGWS() {
  echo " 
  
                                                                   ..........
                                                            ...::----------::..
                                                          ..:------------------:..
                                                        ..:-----:::......::------:.
                                                        ..--::...          ..:------:::..
                                                         ....            ..:------------:..
                                                                         .:-:....  ....:--:
                      .........         ....                       ...    ... .............
                  .-+*########**=.    .=*#*=                      -*##+.    .=**#######**.
                .=*#####****######*:  .-*###.                    .*###=.  .=######**#####:
              .-*###*:..    ...=###+.  .+###=         ...        =###*:  .=###*...  .....
             .-###*-..          ....   .-*###:      .*##*:      .*###=.  .+###-
            .:###*-.                    .+###+     .+####*.     =###*.   .+####+:.
            .=###=.                      :*###:   .=######+.   :*###-     .=#########+:.
            .=###=.        .-======-.     +###+   -*##**##*=   =*##+        .:*##########*:
            .=###=.       .-#######*=     .*##*-.:+###:.###*:.:*###:            ...-+*#####+.
            .:*##*-.       .:---+##*=      =###+.=###-. :###+:=###+                   .:*###=
             .-####-..          +##*=      .*##*+###=.  .=###**##*.         ..         .=###+
              .-*###*-...  ....+###*=       -######+:    .+######-.       .=**:...   ..-###*-
                .=*######***######*-.        +####*-.    .:*####*..       -*#####****#####*-.
                  .:+**#######**=.           :*##*=.      .:*##*-.         .-+*########**-.
                      .........               ....          ....              ..........

            .:... ..... ........ :.....:....:.. ......    ..... .....      .:..::::::..:::::.
            .:... ....:  .:.::.. :.. .......:.. ......    ...:.  .:.     .:::.:..:.  .:......
            ..    .....  ......  :..........:.. ......    .....   .      ::...:....  ..:::::.
                                                                         .::::.                
  
  
  "
}

log() {
  local message="$1"
  #echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
  echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}

#VALIDACION DEL HOSTNAME DEL PROXY zabbix
# Solicitar al usuario que ingrese un dato
echo "Ingrese el Numero de Oportunidad para la creacion del Proxyname:"
read HOSTNAME_PROXY

# Validar si se ingresó un dato
if [ -z "$HOSTNAME_PROXY" ]; then
    log "¡Error! No se ingresó ningún dato, porfavor volver a intentar a ejecutar el Script"
    exit 1
else
    log "Has ingresado la siguiente Oportunidad: $HOSTNAME_PROXY para nombrar al Proxyname"
fi

#************** ENCRIPTACION DE ZABBIX PROXY *******************************************
# Generar una llave PSK de 32 bytes en formato hexadecimal
PSK=$(openssl rand -hex 32)

# Mostrar la llave PSK
log "La llave PSK generada es: $PSK"

# Crear el archivo en /opt con el nombre encrypted.key
echo "$PSK" > /opt/encrypted.key

# Banners y funciones de mensajes
BannerConfZabbixProxy() {
  echo "
 
    ####    #####   ##   ##  #######                    ######   ######    #####   ##  ##   ##  ##            #######    ##     ######   ######    ####    ##  ##
  ##  ##  ##   ##  ###  ##   ##   #                     ##  ##   ##  ##  ##   ##  ##  ##   ##  ##            #   ##    ####     ##  ##   ##  ##    ##     ##  ##
 ##       ##   ##  #### ##   ## #                       ##  ##   ##  ##  ##   ##   ####    ##  ##               ##    ##  ##    ##  ##   ##  ##    ##      ####
 ##       ##   ##  ## ####   ####                       #####    #####   ##   ##    ##      ####               ##     ##  ##    #####    #####     ##       ##
 ##       ##   ##  ##  ###   ## #                       ##       ## ##   ##   ##   ####      ##               ##      ######    ##  ##   ##  ##    ##      ####
  ##  ##  ##   ##  ##   ##   ##        ##               ##       ##  ##  ##   ##  ##  ##     ##              ##    #  ##  ##    ##  ##   ##  ##    ##     ##  ##
   ####    #####   ##   ##  ####       ##              ####     #### ##   #####   ##  ##    ####             #######  ##  ##   ######   ######    ####    ##  ##


 
  "
}

# FUNCIÓN PARA INSTALAR Y CONFIGURAR ZABBIX PROXY
Config_zabbix_proxy() {

  log "=============================="
  log "configuracion de Zabbix Proxy"
  log "=============================="

  sed -i "s/^Server=.*/Server=$ZABBIX_SERVER_IP/" /etc/zabbix/zabbix_proxy.conf
  sed -i "s/^Hostname=.*/Hostname=$HOSTNAME_PROXY/" /etc/zabbix/zabbix_proxy.conf
  sed -i "s/^# TLSConnect=.*/TLSConnect=psk/" /etc/zabbix/zabbix_proxy.conf
  sed -i "s/^# TLSAccept=.*/TLSAccept=psk/" /etc/zabbix/zabbix_proxy.conf
  sed -i "s/^# TLSPSKIdentity=.*/TLSPSKIdentity=$HOSTNAME_PROXY/" /etc/zabbix/zabbix_proxy.conf
  sed -i "s|^# TLSPSKFile=.*|TLSPSKFile=$ZABBIX_PROXY_PSK|" /etc/zabbix/zabbix_proxy.conf

  systemctl restart zabbix-proxy
  systemctl enable zabbix-proxy

  if systemctl is-active --quiet zabbix-proxy; then
    log "**********************"
    log "Zabbix Proxy editado y corriendo exitosamente."
    log "**********************"
  else
    log "Error al iniciar Zabbix Proxy."
    exit 1
  fi
}

# Funcion de Recargar la caché de configuración de Zabbix Proxy
RecargaCache() {

log "Recargando la caché de configuración de Zabbix Proxy..."
if zabbix_proxy -R config_cache_reload | grep -q "successful"; then
  log "La recarga de la caché de configuración fue exitosa."
else
  log "Error: No se pudo recargar la caché de configuración de Zabbix Proxy."
  exit 1
fi
}


log
BannerGWS
BannerConfZabbixProxy
Config_zabbix_proxy
RecargaCache

rm -- "$0"
