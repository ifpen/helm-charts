# MediaWiki Helm Chart

Chart Helm pour déployer [MediaWiki 1.45](https://www.mediawiki.org/) sur Kubernetes.

MediaWiki est le moteur de wiki open-source utilisé par Wikipédia et des milliers d'autres wikis dans le monde.

## Prérequis

- Helm 3.0+
- Kubernetes 1.19+

## Installation

### Ajouter le dépôt Helm

```bash
helm repo add ifpen https://ifpen.github.io/helm-charts/
helm repo update
```

### Installation avec les valeurs par défaut (MariaDB interne)

```bash
helm install mon-wiki ifpen/mediawiki \
  --set mediawiki.siteUrl="https://wiki.example.com" \
  --set mediawiki.siteName="Mon Wiki" \
  --set mediawiki.adminEmail="admin@example.com"
```

### Installation avec une base de données externe

```bash
helm install mon-wiki ifpen/mediawiki \
  --set mediawiki.siteUrl="https://wiki.example.com" \
  --set mediawiki.siteName="Mon Wiki" \
  --set mariadb.internal.enabled=false \
  --set mariadb.external.enabled=true \
  --set mariadb.external.host="mariadb.example.com" \
  --set mariadb.external.database="mediawiki" \
  --set mariadb.external.user="mediawiki" \
  --set mariadb.external.password="mot-de-passe"
```

### Installation avec un fichier de valeurs personnalisé

```bash
helm install mon-wiki ifpen/mediawiki -f mes-valeurs.yaml
```

## Initialisation de la base de données

La base de données MediaWiki est initialisée **automatiquement** lors du premier déploiement grâce au conteneur d'initialisation `init-db`. Aucune intervention manuelle n'est requise.

Pour vérifier le statut de l'initialisation, consultez les logs du conteneur init-db :

```bash
kubectl logs -l app.kubernetes.io/instance=mon-wiki -c init-db
```

### Mise à jour du schéma après une mise à jour de MediaWiki

Après une mise à jour de la version de MediaWiki, exécutez le script de mise à jour du schéma :

```bash
kubectl exec -it deployment/mon-wiki-mediawiki -- php /var/www/html/maintenance/update.php --quick
```

## Configuration

### Paramètres principaux

| Paramètre | Description | Valeur par défaut |
|-----------|-------------|-------------------|
| `mediawiki.siteName` | Nom du wiki | `"Mon Wiki"` |
| `mediawiki.siteUrl` | URL de base du wiki | `"https://wiki.example.com"` |
| `mediawiki.language` | Code de langue de l'interface | `"fr"` |
| `mediawiki.adminUser` | Nom du compte administrateur | `"admin"` |
| `mediawiki.adminPassword` | Mot de passe admin (généré si vide) | `""` |
| `mediawiki.adminEmail` | Email de l'administrateur | `"admin@example.com"` |
| `mediawiki.secretKey` | Clé secrète sessions (générée si vide) | `""` |
| `mediawiki.upgradeKey` | Clé de mise à jour (générée si vide) | `""` |
| `mediawiki.allowAnonymousEditing` | Autoriser les modifications anonymes | `false` |
| `mediawiki.userCanCreateAccount` | Permettre la création de compte | `true` |
| `mediawiki.timezone` | Fuseau horaire | `"Europe/Paris"` |

### Configuration de la base de données (MariaDB interne)

| Paramètre | Description | Valeur par défaut |
|-----------|-------------|-------------------|
| `mariadb.internal.enabled` | Activer MariaDB interne | `true` |
| `mariadb.internal.database` | Nom de la base de données | `"mediawiki"` |
| `mariadb.internal.user` | Utilisateur de la base de données | `"mediawiki"` |
| `mariadb.internal.password` | Mot de passe (généré si vide) | `""` |
| `mariadb.internal.rootPassword` | Mot de passe root (généré si vide) | `""` |
| `mariadb.internal.persistence.enabled` | Activer la persistance | `true` |
| `mariadb.internal.persistence.size` | Taille du volume | `"8Gi"` |

### Configuration de la base de données externe

| Paramètre | Description | Valeur par défaut |
|-----------|-------------|-------------------|
| `mariadb.external.enabled` | Utiliser une base de données externe | `false` |
| `mariadb.external.host` | Hôte de la base de données | `"mariadb.example.com"` |
| `mariadb.external.port` | Port de la base de données | `3306` |
| `mariadb.external.database` | Nom de la base de données | `"mediawiki"` |
| `mariadb.external.user` | Utilisateur | `"mediawiki"` |
| `mariadb.external.password` | Mot de passe | `""` |
| `mariadb.external.existingSecret` | Secret Kubernetes existant | `""` |

### Persistance

| Paramètre | Description | Valeur par défaut |
|-----------|-------------|-------------------|
| `persistence.enabled` | Activer la persistance des images/uploads | `true` |
| `persistence.size` | Taille du volume | `"10Gi"` |
| `persistence.accessMode` | Mode d'accès | `ReadWriteOnce` |
| `persistence.storageClass` | Classe de stockage | `""` |

### Ingress

| Paramètre | Description | Valeur par défaut |
|-----------|-------------|-------------------|
| `ingress.enabled` | Activer l'Ingress | `false` |
| `ingress.className` | Classe d'Ingress | `"nginx"` |
| `ingress.hosts` | Hôtes de l'Ingress | voir `values.yaml` |
| `ingress.tls` | Configuration TLS | `[]` |

### Network Policy

| Paramètre | Description | Valeur par défaut |
|-----------|-------------|-------------------|
| `networkPolicy.enabled` | Activer les NetworkPolicies | `true` |

Lorsque `networkPolicy.enabled` est `true`, deux `NetworkPolicy` sont créées :

- **mediawiki** : autorise les flux entrants sur le port 80 (HTTP) et les flux sortants vers MariaDB (port 3306) et vers le DNS (port 53).
- **mariadb** (si `mariadb.internal.enabled`) : autorise les flux entrants depuis le pod MediaWiki sur le port 3306 et les flux sortants vers le DNS (port 53).

## Désinstallation

```bash
helm uninstall mon-wiki
```

> **Note :** Les PersistentVolumeClaims ne sont pas supprimés automatiquement. Pour les supprimer manuellement :
> ```bash
> kubectl delete pvc -l app.kubernetes.io/instance=mon-wiki
> ```
