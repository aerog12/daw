#!/bin/bash


# Comando para crear usuario Tomcat
sudo useradd -m -d /opt/tomcat -U -s /bin/false tomcat

# Comandos para actualizar la caché del administrador de paquetes e instalar JDK, en nuestro caso el 17
sudo apt update
sudo apt upgrade -y
sudo apt install -y openjdk-17-jdk

# Comandos para descargar e instalar Apache Tomcat, en nuestro caso, la version 10.1.18 que es la ultima
#variable con el numero de la version para usarla posteriormente

TOMCAT_VERSION="10.1.18"
sudo wget https://dlcdn.apache.org/tomcat/tomcat-10/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz -P /tmp
sudo tar xzvf /tmp/apache-tomcat-${TOMCAT_VERSION}.tar.gz -C /opt/tomcat --strip-components=1

# Configuracion de los permisos de tomcat
sudo chown -R tomcat:tomcat /opt/tomcat/
sudo chmod -R u+x /opt/tomcat/bin

# Configurarion de los usuarios en tomcat-users.xml
sudo tee -a /opt/tomcat/conf/tomcat-users.xml > /dev/null <<EOL
<role rolename="manager-gui" />
<user username="manager" password="manager_password" roles="manager-gui" />

<role rolename="admin-gui" />
<user username="admin" password="admin_password" roles="manager-gui,admin-gui" />
EOL

# Comandos para eliminar las restricciones de acceso en context.xml
sudo sed -i '/<Valve/,/<\/Context>/ s/^/<!--/' /opt/tomcat/webapps/manager/META-INF/context.xml
sudo sed -i '/<Valve/,/<\/Context>/ s/$/-->/g' /opt/tomcat/webapps/manager/META-INF/context.xml

sudo sed -i '/<Valve/,/<\/Context>/ s/^/<!--/' /opt/tomcat/webapps/host-manager/META-INF/context.xml
sudo sed -i '/<Valve/,/<\/Context>/ s/$/-->/g' /opt/tomcat/webapps/host-manager/META-INF/context.xml


# Configuracion del servicio systemd
JAVA_HOME=$(sudo update-java-alternatives -l | awk '{print $3}')
sudo tee /etc/systemd/system/tomcat.service > /dev/null <<EOL
[Unit]
Description=Tomcat
After=network.target

[Service]
Type=forking

User=tomcat
Group=tomcat

Environment="JAVA_HOME=${JAVA_HOME}"
Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom"
Environment="CATALINA_BASE=/opt/tomcat"
Environment="CATALINA_HOME=/opt/tomcat"
Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOL

# Comando para recargar systemd
sudo systemctl daemon-reload

# Comandos para iniciar Tomcat y habilitar el inicio automático
sudo systemctl start tomcat
sudo systemctl enable tomcat

# Comando para la eliminación del archivo de instalacion de tomcat despues de la instalacion. 
sudo rm /tmp/apache-tomcat-${TOMCAT_VERSION}.tar.gz

#permitir trafico al puerto 8080
sudo ufw allow 8080

echo "Apache Tomcat ${TOMCAT_VERSION} instalado correctamente en /opt/tomcat."
