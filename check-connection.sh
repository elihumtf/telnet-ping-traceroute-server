#!/bin/bash

echo Se va a proceder al envio del correo de Estado de Conexion
read -p "Defina a que correo enviar dicha informacion: " correo

fichero=check-connection-`date -I`.txt
echo ---------------------------------------------------------------------------- >> $fichero
echo Estadisticas de conexion del dia `date` >> $fichero
echo ---------------------------------------------------------------------------- >> $fichero
echo >> $fichero


while IFS=: read -r ip puerto
do
# Realización de TELNET
    echo "SERVIDOR ""$ip" >> $fichero
    nc -vz "$ip" "$puerto" |& tee telnet.txt
    cut -d " " -f 7 telnet.txt > solucion.txt
    cut -d "!" -f 1 solucion.txt > variable.txt
    variable=$(cat variable.txt)
    if [ "$variable" == "succeeded" ];
    then
        echo "1. TELNET OK" >> $fichero
        rm -rf telnet.txt solucion.txt variable.txt
    else
        echo "1. TELNET KO" >> $fichero
        rm -rf telnet.txt solucion.txt variable.txt
    fi

#Realización de PING

    ping -c 5 "$ip" |& tee ping.txt
    sed -i '1,8d' ping.txt
    sed -i '2d' ping.txt
    cut -d "," -f 2 ping.txt > ping-resultado.txt
    resultadoping=$(cat ping-resultado.txt)

    if [ "$resultadoping" == " 5 received" ];
    then
        echo "2. Ping Ok" >> $fichero
        rm -rf ping.txt ping-resultado.txt
    else
        echo "2. Ping KO" >> $fichero
        rm -rf ping.txt ping-resultado.txt
    fi

# Realización de TRACEROUTE
    echo 3. Realizacion del Traceroute al Servidor "$ip" al puerto "$puerto" >> $fichero
    echo ---------------------------------------------------------------------------- >> $fichero
    traceroute -p "$puerto" "$ip" >> $fichero
    echo >> $fichero
    echo ---------------------------------------------------------------------------- >> $fichero
    echo ---------------------------------------------------------------------------- >> $fichero
    echo >> $fichero
done < ip-port.txt

echo Se ha enviado correo con los datos recogidos.
mail -s 'Estado de los nodos a fecha '`date -I` $correo -a From:[user]\<[email]\> < $fichero
