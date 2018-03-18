# Dépôts des configurationdes Install et des fichiers nécessaires aux install

Les configurations peuvent se présenter sous forme de fichier texte "classique" ou sous forme de templates Jinja (j2). 

Ce dépôt est appelé par Ansible pour récupérer la version la plus à jour d'une configuration/template/paquet spécfique. 


```
Oubliant qu'on est en 2015, les autres personnes browse un partage Samba pour obtenir un programme ... l'idée de ce dépôt est d'apporter :

    1) une facilitée d'accès à la ressource (web)
    2) un accès étendu (ouvert en any)
    3) un historique des version
    4) un contrôle d'accès fin
    5) un découpage fonctionnel par projet par exemple
    4) et plein d'autre chose ...  

```
```
.
|-- Apps
|   `-- Webapps         <-- seulement Magento pour l'instant
|-- Centos              <-- non peuplé
|   `-- 6.4         
`-- Debian
    |-- jessie          <-- peuplé - uptodate (Apache 2.4 à compléter et manque mysql 5.6)
    |-- README.md       
    |-- squeeze         <-- non peuplé
    `-- wheezy          <-- Historique - uptodate

```

