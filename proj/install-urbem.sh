#!/bin/bash

ROOT_PATH_PROJECT="/datacenter"
#ROOT_PATH_PROJECT="/home/rcruz/Projetos"
URL_ENV_URBEM_DOCKER="https://github.com/robsonscruz/env-urbem/archive/master.zip"
VERSION_URBEM="201711151640"
URL_PROJECT_URBEM="https://github.com/tilongevo/urbem3.0/archive/v${VERSION_URBEM}.zip"
URL_PROJECT_TRANSPARENCIA="https://github.com/tilongevo/urbem-transparencia/archive/v1.2.1.zip"
URL_PROJECT_REDE_SIMPLES="https://github.com/tilongevo/rede-simples/archive/v201711211030.zip"
URL_BANCO_DADOS="https://github.com/tilongevo/banco-zerado-urbem3.0/archive/master.zip"

installDocker() {
    echo "Instalando Docker..."
    apt-get update
    apt-get install git
    apt-get install -y apt-transport-https ca-certificates
    apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
    apt-add-repository 'deb https://apt.dockerproject.org/repo ubuntu-xenial main'
    apt-get update
    apt-cache policy docker-engine
    apt-get install -y docker-engine wget zip unzip htop
    docker swarm init
    docker swarm join-token --quiet worker > /home/ubuntu/token
    curl -o /usr/local/bin/docker-compose -L https://github.com/docker/compose/releases/download/1.12.0/docker-compose-$(uname -s)-$(uname -m)
    chmod +x /usr/local/bin/docker-compose

    echo "Instalacao do Docker finalizada."
}

permissionUserLoggedDocker() {
    echo "Aplicando permissao ao usuario executar o Docker"
    sudo usermod -aG docker ubuntu
}

createRootPathEnvDocker() {
    echo "Criando pasta padrao para execucao do projeto"
    mkdir -p /${ROOT_PATH_PROJECT}
    chown -Rf root:ubuntu /${ROOT_PATH_PROJECT}
    chmod 775 -Rf /${ROOT_PATH_PROJECT}
}

downloadEnvUrbem() {
    echo "Executando download do EnvUrbem - Docker"
    cd /${ROOT_PATH_PROJECT} && wget ${URL_ENV_URBEM_DOCKER}
    cd /${ROOT_PATH_PROJECT} && unzip master.zip && mv env-urbem-master env-urbem && rm master.zip
    cd /${ROOT_PATH_PROJECT}/env-urbem && mv volumes.yml.dist volumes.yml
}

downloadUrbem() {
    echo "Executando download do Urbem 3.0"
    cd /${ROOT_PATH_PROJECT} && wget ${URL_PROJECT_URBEM}
    cd /${ROOT_PATH_PROJECT} && unzip v${VERSION_URBEM}.zip
    cd /${ROOT_PATH_PROJECT}/env-urbem/www && rm -rf urbem-prod
    cd /${ROOT_PATH_PROJECT} && mv urbem3.0-${VERSION_URBEM} /${ROOT_PATH_PROJECT}/env-urbem/www/urbem-prod && rm v${VERSION_URBEM}.zip
}

downloadPortalDaTransparencia() {
    echo "Executando download do Portal da Transparencia"
    cd /${ROOT_PATH_PROJECT} && wget ${URL_PROJECT_TRANSPARENCIA}
    cd /${ROOT_PATH_PROJECT} && unzip v1.2.1.zip
    cd /${ROOT_PATH_PROJECT}/env-urbem/www && rm -rf transparencia-prod
    cd /${ROOT_PATH_PROJECT} && mv urbem-transparencia-1.2.1 /${ROOT_PATH_PROJECT}/env-urbem/www/transparencia-prod && rm v1.2.1.zip
    chmod 777 -Rf /${ROOT_PATH_PROJECT}/env-urbem/www/transparencia-prod/uploads
    chmod 777 -Rf /${ROOT_PATH_PROJECT}/env-urbem/www/transparencia-prod/tmp
}

downloadRedeSimples() {
    echo "Executando download do Rede Simples"
    cd /${ROOT_PATH_PROJECT} && wget ${URL_PROJECT_REDE_SIMPLES}
    cd /${ROOT_PATH_PROJECT} && unzip v201711211030.zip
    cd /${ROOT_PATH_PROJECT}/env-urbem/www && rm -rf redesimples-prod
    cd /${ROOT_PATH_PROJECT} && mv rede-simples-201711211030 /${ROOT_PATH_PROJECT}/env-urbem/www/redesimples-prod && rm v201711211030.zip
    chmod 777 -Rf /${ROOT_PATH_PROJECT}/env-urbem/www/redesimples-prod/web/datafiles
    chmod 777 -Rf /${ROOT_PATH_PROJECT}/env-urbem/www/redesimples-prod/database
}

downloadDatabases() {
    echo "Executando download dos bancos necessarios para criacao de todo parque Longevo/Urbem"
    cd /${ROOT_PATH_PROJECT}/env-urbem/www/urbem-prod && sudo rm -rf banco-zerado-urbem3.0
    cd /${ROOT_PATH_PROJECT} && wget ${URL_BANCO_DADOS}
    cd /${ROOT_PATH_PROJECT} && unzip master.zip
    cd /${ROOT_PATH_PROJECT} && mv banco-zerado-urbem3.0-master /${ROOT_PATH_PROJECT}/env-urbem/www/urbem-prod/banco-zerado-urbem3.0 && rm master.zip
    cd /${ROOT_PATH_PROJECT}/env-urbem/www/urbem-prod/banco-zerado-urbem3.0 && tar -xzvf rede-simples.sql.tar.gz && tar -xzvf transparencia-zerado.sql.tar.gz && tar -xzvf urbem-zerado.tar.gz
}

createPathTempUrbem() {
    echo "Criando pastas temporarias para execucao do Urbem - cache, logs, sessions"
    mkdir -p /${ROOT_PATH_PROJECT}/env-urbem/www/urbem-prod/var
    chmod 777 -Rf /${ROOT_PATH_PROJECT}/env-urbem/www/urbem-prod/var
}

reinitializeDocker() {
    echo "Reiniciando Docker"
    cd /${ROOT_PATH_PROJECT}/env-urbem && sudo docker-compose build && sudo docker-compose up -d && sudo docker-compose up -d --force-recreate
}

initializeUrbem() {
    echo "Inicializando Urbem 3.0"
    sudo docker exec envurbem_web-urbem_1 php /srv/www/urbem/vendor/sensio/distribution-bundle/Resources/bin/build_bootstrap.php
    sudo docker exec envurbem_web-urbem_1 php /srv/www/urbem/bin/console cache:clear --no-warmup --env=prod
    sudo docker exec envurbem_web-urbem_1 php /srv/www/urbem/bin/console cache:warmup --env=prod
    sudo docker exec envurbem_web-urbem_1 /srv/www/urbem/bin/console assetic:dump --no-debug
    sudo docker exec envurbem_web-urbem_1 /srv/www/urbem/bin/console assets:install /srv/www/urbem/web --symlink --relative -vvv
    sudo chmod 777 -Rf /${ROOT_PATH_PROJECT}/env-urbem/www/urbem-prod/var
    sudo chmod 777 -Rf /${ROOT_PATH_PROJECT}/env-urbem/www/urbem-prod/var/*
    sudo chmod 777 -Rf /${ROOT_PATH_PROJECT}/env-urbem/www/storage
    sudo docker exec envurbem_web-urbem_1 touch /var/www/storage/prefeitura.yml
    sudo chmod 777 -Rf /${ROOT_PATH_PROJECT}/env-urbem/www/storage/*
}

permissionPathStorage() {
    sudo chmod 777 -Rf /${ROOT_PATH_PROJECT}/env-urbem/www/urbem-prod/var
    sudo chmod 777 -Rf /${ROOT_PATH_PROJECT}/env-urbem/www/urbem-prod/var/*
    sudo chmod 777 -Rf /${ROOT_PATH_PROJECT}/env-urbem/www/storage
    sudo chmod 777 -Rf /${ROOT_PATH_PROJECT}/env-urbem/www/storage/*
}

importDBUrbem() {
    sudo docker exec envurbem_web-redesimples_1 /sbin/importTransparencia.sh
    sudo docker exec envurbem_web-redesimples_1 /sbin/importUrbem.sh
    sudo docker exec envurbem_web-redesimples_1 /sbin/importETL.sh
}

importDBRedeSimples() {
    echo "Importando banco de dados Rede Simples"
    sudo docker exec envurbem_web-redesimples_1 /sbin/importRedeSimples.sh
}

updateDatabaseUrbem() {
    sudo docker exec envurbem_web-urbem_1 php /srv/www/urbem/bin/console doc:mi:mi --env=prod --no-interaction
}

#PROD
installDocker
permissionUserLoggedDocker
createRootPathEnvDocker
downloadEnvUrbem

# DEV
downloadUrbem
downloadPortalDaTransparencia
downloadRedeSimples
downloadDatabases
createPathTempUrbem
reinitializeDocker
initializeUrbem

importDBRedeSimples
importDBUrbem

#PROD
permissionPathStorage
updateDatabaseUrbem
reinitializeDocker

#drop database urbem; create database urbem; GRANT all ON DATABASE urbem TO docker;
#drop database etl; create database etl; GRANT all ON DATABASE etl TO docker;
#drop database "urbem-transparencia"; create database "urbem-transparencia"; GRANT all ON DATABASE "urbem-transparencia" TO docker;