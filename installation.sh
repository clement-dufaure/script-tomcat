#!/bin/bash

export tomcat_version_major=9
export tomcat_version_medium=0
export tomcat_version_minor=31
export tomcat_version=${tomcat_version_major}.${tomcat_version_medium}.${tomcat_version_minor}

curl https://downloads.apache.org/tomcat/tomcat-${tomcat_version_major}/v${tomcat_version}/bin/apache-tomcat-${tomcat_version}.tar.gz | tar -xz

mkdir apache-tomcat-${tomcat_version}/conf/ssl

# creation d'un certif autosigne pour localhost
openssl genrsa 2048 > apache-tomcat-${tomcat_version}/conf/ssl/server.key
openssl req -new -key apache-tomcat-${tomcat_version}/conf/ssl/server.key -out apache-tomcat-${tomcat_version}/conf/ssl/server.csr -subj "//CN=localhost"
openssl x509 -req -days 365 -in apache-tomcat-${tomcat_version}/conf/ssl/server.csr  -signkey apache-tomcat-${tomcat_version}/conf/ssl/server.key  -out apache-tomcat-${tomcat_version}/conf/ssl/server.crt
openssl pkcs12 -export -in apache-tomcat-${tomcat_version}/conf/ssl/server.crt -inkey apache-tomcat-${tomcat_version}/conf/ssl/server.key -out apache-tomcat-${tomcat_version}/conf/ssl/server.p12 -passout pass:changeit

# Creation d'un truststore avec le certif localhost
keytool -noprompt -import -trustcacerts -file apache-tomcat-${tomcat_version}/conf/ssl/acsubordonnee.crt -alias acsubordonnee -keystore apache-tomcat-${tomcat_version}/conf/ssl/cacerts -storepass changeit

# Configuration du port d'ecoute https 8443 avec certificat serveur
sed -i "/<\/Service>/ i \
<Connector port=\"8443\" protocol=\"org.apache.coyote.http11.Http11NioProtocol\" \n\
          maxThreads=\"150\" SSLEnabled=\"true\" scheme=\"https\" secure=\"true\" \n\
          clientAuth=\"false\" sslProtocol=\"TLS\" \n\
          keystoreFile=\"\${catalina.home}/conf/ssl/server.p12\" keystoreType=\"pkcs12\" keystorePass=\"changeit\" \n\
/>" apache-tomcat-${tomcat_version}/conf/server.xml

# Conf dans eclipse si ncessite de connexion inter appli sur le meme tomcat en https
printf "Ajouter les arguments VM suivants dans eclipse : \n\
-Djavax.net.ssl.trustStore=\"$(pwd -W)/apache-tomcat-${tomcat_version}/conf/ssl/cacerts\" \
-Djavax.net.ssl.trustStorePassword=changeit \
-Djavax.net.ssl.trustStoreType=JKS
" > README.txt
