# DecPurchaseOrder

Démo d'un microservice implementé et déployé à l'aide du stack webMethods:
- Designer pour la partie développement
- Microservice runtime pour la partie déploiement

## Architecture



## Environnement de développement

Le designer est disponible à cet adresse: https://tech.forums.softwareag.com/t/webmethods-service-designer-download/235227
Le bundle embraque un microservice runtime (version allégée de l'integration server optimisée pour les microservices) avec une license d'essai valable 1 an.
Le tout fonctionne sous Windows, MacOS (Intel et Apple Silicon) et Linux.
Pas besoin d'une grosse configuration pour faire fonctionner tout ça, le MSR nécessite peu de ressources physiques.

Si nécessaire vous pouvez jeter un oeil à cette page pour la prise en main de l'environnement: https://tech.forums.softwareag.com/t/webmethods-service-designer-first-steps-tutorials-how-tos/263745

On utilise le Designer pour mettre en place les intégrations. Approche webMethods classique, sauf qu'on utilise donc un MSR au lieu d'un IS.
L'édition des Dockerfile, manisfestes Kubernetes, scripts et autres fichiers (en dehors de ceux générés par le Designer) se fait avec n'importe quel IDE (VS Code, Atom, Notepad++, voir même le Designer en changeant la perspective...)
Pour Git, le client Eclipse fait le job mais vous pouvez utiliser la ligne de commande ou un outil GUI style SourceTree.
Pour Docker (ou containerd, podman, ...), ça se passe avec la ligne de commande.
Pour Kubernetes, ça se passe également avec la ligne de commande et avec l'outil kubectl.
Le reste se gère dans le navigateur web, notament Azure Pipelines.

## Clonage du repository Github


## Configuration du microservice


## Build de l'image de base


## Build de l'image du microservice


## Déploiement Docker (ou équivalent)


## Déploiement Kubernetes


## Tests fonctionnels


## Pipeline de CI/CD

