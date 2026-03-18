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

Lors du premier déploiement, vous devez initialiser la base de données MediaWiki en exécutant le script d'installation :

```bash
# Récupérer les mots de passe depuis les secrets Kubernetes
export MW_DB_PASS=$(kubectl get secret mon-wiki-mediawiki -o jsonpath="{.data.mariadb-password}" | base64 -d)
export MW_ADMIN_PASS=$(kubectl get secret mon-wiki-mediawiki -o jsonpath="{.data.mediawiki-admin-password}" | base64 -d)

# Lancer l'installation
kubectl exec -it deployment/mon-wiki-mediawiki -- php /var/www/html/maintenance/install.php \
  --dbserver=mon-wiki-mediawiki-mariadb \
  --dbname=mediawiki \
  --dbuser=mediawiki \
  --dbpass="${MW_DB_PASS}" \
  --pass="${MW_ADMIN_PASS}" \
  --scriptpath="" \
  "Mon Wiki" \
  "admin"
```

Les commandes exactes sont affichées dans les notes après l'installation (`helm status mon-wiki`).

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

## Désinstallation

```bash
helm uninstall mon-wiki
```

> **Note :** Les PersistentVolumeClaims ne sont pas supprimés automatiquement. Pour les supprimer manuellement :
> ```bash
> kubectl delete pvc -l app.kubernetes.io/instance=mon-wiki
> ```
