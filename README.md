# DecPurchaseOrder

Démo d'un microservice implementé et déployé à l'aide du stack webMethods:
- Designer pour la partie développement
- Microservice runtime pour la partie déploiement

Ce microservice se connecte à une base de données relationnelle à l'aide du connecteur JDBC webMethods.
Il publie des messages dans un broker Kafka.
Il est également appelé par un flow service déployé sur l'iPaaS webMethods.io, en utilsant les mécanismes d'intégration hybride.

Le code présenté ici correspond au contenu du package webMethods, enrichit avec un Dockerfile pour le build de l'image, un yaml pour le CI/CD Azure Pipelines et d'autres ressources diverses positionnées dans le répertoire resources.

## Architecture

![Architecture](https://github.com/staillansag/msr-dec-purchase-order/blob/master/resources/images/DecPurchaseOrder_architecture.png)

## Ressources externes

### Base de données Postgres

Le microservice accède à une table nommée decorders dans la base sandbox.
Voici le DDL pour créer cette table. Les puristes pourront ajouter une clé primaire et des longueurs explicites pour les varchar, j'ai voulu ici simplifier au maximum:
```
CREATE TABLE public.decorders (
	transactionid varchar NOT NULL,
	supplierid varchar NOT NULL,
	processingdatetime timestamp NOT NULL,
	documentid varchar NOT NULL,
	street varchar NULL,
	postcode varchar NULL,
	city varchar NULL,
	country varchar NULL,
	orderreference varchar NULL,
	orderstatus varchar NULL
);
```

### Kafka

Le microservice insère des messages dans un topic nommé TestTopic, qui doit donc être créé dans le broker Kafka cible.

### webMethods.io Integration

TODO

## Configuration du microservice

L'image Docker intègre un fichier application.properties qui permet la connexion à une base de données relationelle, à un broker Kafka et à un tenant webMethods.io .
Les propriétés de connexions sont associées à des variables d'environnement, de telle sorte qu'on peut modifier ces propriétés sans avoir besoin de modifier l'image.

Par exemple, la propriété suivante permet de configurer le nom du serveur de la base de données, et pointe sur la variable d'environnement DB_SERVERNAME.
```
artConnection.DecPurchaseOrder.DecPurchaseOrder.jdbc.DecPurchaseOrder_jdbc.connectionSettings.serverName=$env{DB_SERVERNAME}
```

Pour un déploiement Docker simple on passera un fichier .env en paramètre pour configurer ces variables d'environnement.
Pour un déploiement Kubernetes, on ira chercher les valeurs des variables d'environnement dans un configMap et un secret, qui sont des objets Kubernetes spécialement étudiés pour la configuration.

## Build de l'image

### Approche méthodologique

![Schéma](https://github.com/staillansag/msr-dec-purchase-order/blob/master/resources/images/ImageBuild.png)

Le principe est de suivre une démarche en deux étapes pour construire l'image du microservice : d'abord construire une image de base, ensuite ajouter le code et la configuration spécifique au microservice.
La construction de l'image de base peut être confiée à une équipe transverse. Cette image de base suit un cycle de vie spécifique et elle peut potentiellement être utilisée par plusieurs microservices développés par des équipes différentes.
En suivant cette approche, l'équipe en charge de développer le microservice n'a pas à gérer les upgrades de produits, d'OS ou les patches de sécurité. Elle peut se concentrer sur les aspects fonctionnels du microservice.

### Image de base

On peut construire cette image de base en partant de zéro, avec l'aide des outils SAG: https://github.com/SoftwareAG/sag-unattended-installations
Approche assez complexe, à privilégier uniquement si vous souhaitez avoir une maîtrise totale du contenu de l'image et de l'OS de base.

L'approche la plus simple est d'utiliser une image SAG "sur étagère" pour construire une nouvelle image enrichie.

Dockerfile de construction de l'image de base (ici on ajoute les adaptateurs JDBC, Kafka et SAP):
```
FROM softwareag/webmethods-microservicesruntime:10.15.0.1-ubi

ENV LD_LIBRARY_PATH=/opt/softwareag/IntegrationServer/lib

# define exposed ports

EXPOSE 5555
EXPOSE 5543
EXPOSE 9999


# user to be used when running scripts
USER sagadmin


# files to be added to based image (includes configuration and package)

ADD --chown=sagadmin packages/WmJDBCAdapter /opt/softwareag/IntegrationServer/packages/WmJDBCAdapter
ADD --chown=sagadmin packages/WmKafkaAdapter /opt/softwareag/IntegrationServer/packages/WmKafkaAdapter
ADD --chown=sagadmin packages/WmSAP /opt/softwareag/IntegrationServer/packages/WmSAP
ADD --chown=sagadmin lib/libsapjco3.so /opt/softwareag/IntegrationServer/lib/libsapjco3.so
```

Commande de build:
```
docker build -t "${BASE_IMAGE_TAG}"
```

On part ici d'une image officielle SAG publiée sur Dockerhub.
On peut également utiliser une image officielle provenant de https://containers.softwareag.com (qui est devenu la source officielle des conteneurs SAG.)

Note: un outil wpm (webMethods package mabager), très similaire à npm dans son fonctionnement, est en préparation. Il permettra de récupérer et injecter très simplement toutes les dépendances (packages des adaptateurs, modules communs, etc.)
En attendant, les dépendances doivent pour la plupart être récupérées "manuellement" dans un integration server classique.

Note 2: les drivers Postgres, Kafka et SAP doivent être inclus dans cette image de base.

### Image du microservice

Construire l'image du microservice consiste simplement à ajouter le package webMethods.
Ici on ajoute également la définition de l'application cloud (répertoire integrationlive.) Cette définition est nécessaire pour permettre à webMethods.io Integration d'appeler le microservice en utilisant les canaux d'intégration hybride.

```
ARG __from_img

FROM ${__from_img}

# define exposed ports

EXPOSE 5555
EXPOSE 5543
EXPOSE 9999

# user to be used when running scripts
USER sagadmin

# files to be added to based image (includes configuration and package)

ADD --chown=sagadmin . /opt/softwareag/IntegrationServer/packages/DecPurchaseOrder
ADD --chown=sagadmin ./resources/integrationlive /opt/softwareag/IntegrationServer/config/integrationlive
```

Petite subtilité, l'image de base n'est pas codée en dur dans le Dockerfile, elle est passée en argument au moment du build.

Vous pouvez utiliser cette image de base Dockerhub (avec les adaptateurs JDBC, Kakfka et SAP): staillansag/webmethods-microservicesruntime:10.15.0.1-ubi-jksap

```
docker build \
  --build-arg __from_img="${BASE_IMAGE_TAG}" \
  -t "${SERVICE_IMAGE_TAG_BASE}" .
```

Une fois l'image Docker du microservice construire, on peut la pousser dans un registry Docker. Ici j'utilise Dockerhub, mais rien n'empêche d'utiliser une solution équivalente.

```
docker push "${SERVICE_IMAGE_TAG_BASE}"
```


## Déploiement Docker

Note: le principe de fonctionnement est le même si l'on utilise un autre runtime de conteneurs que Docker (podman, containerd, ...)

Première étape : construire un fichier .env contenant toutes les variables d'environnement.

Contenu du fichier .env un exemple est disponible dans le répertoire resources/deployment/docker) :
```
SAG_IS_CONFIG_PROPERTIES=/opt/softwareag/IntegrationServer/packages/DecPurchaseOrder/application.properties
IO_INT_URL=webmethods.io Integration url
IO_INT_USER=webmethods.io user
IO_INT_PASSWORD=webmethods.io password
SERVER_LOCATION=docker
KAFKA_SERVER_LIST=kafka server list
DATASOURCE_CLASS=org.postgresql.ds.PGSimpleDataSource
DB_NAME=Database name
DB_USER=Database user
DB_PASSWORD=Database password
DB_PORT=Database port
DB_SERVERNAME=Database server
```

Ensuite vous pouvez instancier votre conteneur Docker avec cette commande :
```
docker run --name msr-dec-purchase-order -dp 7777:5555 --env-file .env "${SERVICE_IMAGE_TAG_BASE}"
```

En général il faut entre 15 secondes et 1 minutes au MSR pour démarrer.
Ici je mappe le port interne 5555 avec le port externe 7777. Ce qui signifie que l'url de la console d'administration (et l'url de base des APIs) est http://localhost:7777
Vous pouvez vous connecter avec le compte Administrator (mdp = manage)
Il est possible de configurer ce mot de passe par défaut en passant par les properties et par une variable d'environnement, mais je ne l'ai pas mis en oeuvre ici.

## Déploiement Kubernetes

Si vous souhaitez déployer sur AKS, vous pouvez vous appuyer sur ce projet: https://github.com/staillansag/wm-config/tree/main/aks
Vous avez un ensemble de scripts de création et configuration d'un cluster, avec les orchestrations Azure Pipelines qui vont avec.

Les descripteurs de déploiement sont dans le répertoire resources/deployment/kubernetes

La configuration des pods s'appuie sur des objets Kubernetes: une ConfigMap et un Secret (pour les éléments de configuration confidentiels.)
Vous avez des exemples pour ces objets dans 00_msr-purchase-order_configMap.yaml.example et 00_msr-purchase-order_secret.yaml.example
Pour la configMap, les valeurs sont à spécifier en clair.
Pour le secret, les valeurs sont à encoder en base64. Vous pouvez par exemple utiliser cette ligne de commande pour effectuer cet encodage:
```
echo -n 'valeurSecrete' | base64
```

L'ingress controller est configuré pour utiliser nginx. Il faudra peut être l'installer sur votre cluster Kubernetes. La procédure est documentée sur internet.

Une fois la config map, le secret et l'ingress controller configurés, vous pouvez charger les descripteurs yaml à l'aide de la commande suivante:
```
kubectl apply -f .
```

## Tests fonctionnels

J'utilise ici une collection Postman dont l'export json est dans le répertoire resources/test

TODO: ajouter exemple de fichier d'environnement

## Pipeline de CI/CD

Le répertoire resources/buildScripts contient un ensemble de scripts pour gérer
-   le build et les sanity checks de l'image (en la déployant dans un conteneur Docker)
-   le push de l'image dans Dockerhub
-   le déploiement dans le cluster AKS (en mode "rolling update")
-   les tests fonctionnels (en utilisant Newman, la version cli de Postman)
-   si nécessaire, le pipeline peut faire un rollback du déploiement à la précédente version

Ces scripts sont orchestrés par Azure Pipelines. Le pipeline est décrit dans azure-pipelines.yml

Note: j'utilise un agent Azure Pipelines dans lequel j'ai pré-installé Docker (pour le build et le push), kubectl (pour toutes les opérations Kubernetes) et Newman (pour les tests automatisés.)

## Monitoring technique


## Monitoring applicatif