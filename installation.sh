#!/bin/bash

export tomcat_version=9.0.27

export https_proxy=proxy-rie.http.insee.fr:8080
curl https://www-eu.apache.org/dist/tomcat/tomcat-9/v${tomcat_version}/bin/apache-tomcat-${tomcat_version}.tar.gz | tar -xz

mkdir apache-tomcat-${tomcat_version}/conf/ssl

# creation d'un certif autosigne pour localhost
openssl genrsa 2048 > apache-tomcat-${tomcat_version}/conf/ssl/server.key
openssl req -new -key apache-tomcat-${tomcat_version}/conf/ssl/server.key -out apache-tomcat-${tomcat_version}/conf/ssl/server.csr -subj "//C=FR\ST=France\L=Montrouge\O=Insee\OU=SNDIP\CN=localhost"
openssl x509 -req -days 365 -in apache-tomcat-${tomcat_version}/conf/ssl/server.csr  -signkey apache-tomcat-${tomcat_version}/conf/ssl/server.key  -out apache-tomcat-${tomcat_version}/conf/ssl/server.crt
openssl pkcs12 -export -in apache-tomcat-${tomcat_version}/conf/ssl/server.crt -inkey apache-tomcat-${tomcat_version}/conf/ssl/server.key -out apache-tomcat-${tomcat_version}/conf/ssl/server.p12 -passout pass:changeit


# recup des AC Insee
curl crl.insee.fr/pdprdacrwst01_AC%20Racine.crt > apache-tomcat-${tomcat_version}/conf/ssl/acracine.crt
curl crl.insee.fr/pdprdacswst01.ad.insee.intra_AC%20Subordonnee.crt > apache-tomcat-${tomcat_version}/conf/ssl/acsubordonnee.crt

# Creation d'un truststore avec les AC Insee + le certif localhost
keytool -noprompt -import -trustcacerts -file apache-tomcat-${tomcat_version}/conf/ssl/server.crt -alias localhost -keystore apache-tomcat-${tomcat_version}/conf/ssl/cacerts -storepass changeit
keytool -noprompt -import -trustcacerts -file apache-tomcat-${tomcat_version}/conf/ssl/acracine.crt -alias acracine -keystore apache-tomcat-${tomcat_version}/conf/ssl/cacerts -storepass changeit
keytool -noprompt -import -trustcacerts -file apache-tomcat-${tomcat_version}/conf/ssl/acsubordonnee.crt -alias acsubordonnee -keystore apache-tomcat-${tomcat_version}/conf/ssl/cacerts -storepass changeit

# Configuration du port d'ecoute https 8443 avec certificat serveur
sed -i "/<\/Service>/ i \
<Connector port=\"8443\" protocol=\"org.apache.coyote.http11.Http11NioProtocol\" \n\
          maxThreads=\"150\" SSLEnabled=\"true\" scheme=\"https\" secure=\"true\" \n\
          clientAuth=\"false\" sslProtocol=\"TLS\" \n\
          keystoreFile=\"\${catalina.home}/conf/ssl/server.p12\" keystoreType=\"pkcs12\" keystorePass=\"changeit\" \n\
/>" apache-tomcat-${tomcat_version}/conf/server.xml

printf "Ajouter les arguments VM suivants dans eclipse : \n\
-Djavax.net.ssl.trustStore=\"$(pwd -W)/apache-tomcat-${tomcat_version}/conf/ssl/cacerts\" \
-Djavax.net.ssl.trustStorePassword=changeit \
-Djavax.net.ssl.trustStoreType=JKS
" > README.txt


