# Helm Charts

Collection de charts Helm pour Kubernetes, maintenus par [ifpen](https://github.com/ifpen).

## Charts disponibles

<!-- CHART-TABLE-START -->
| Chart | Version | Description |
|-------|---------|-------------|
| [filesender](charts/filesender/) | 3.6.1 | FileSender v3.6 - Application web open-source de partage de fichiers volumineux avec SimpleSAMLphp et Nginx intégrés |
<!-- CHART-TABLE-END -->

Consultez le README de chaque chart pour la documentation complète et les options de configuration.

## Prérequis

- [Helm](https://helm.sh/) 3.0+
- Un cluster Kubernetes 1.19+

## Utilisation

### Ajouter le repository Helm

```bash
helm repo add ifpen https://ifpen.github.io/helm-charts/
helm repo update
```

### Installer un chart avec les valeurs par défaut

```bash
helm install <release-name> ifpen/<chart-name>
```

Par exemple, pour installer FileSender :

```bash
helm install filesender ifpen/filesender
```

### Installer avec un fichier de valeurs personnalisé

```bash
helm install <release-name> ifpen/<chart-name> -f my-values.yaml
```

### Désinstaller un chart

```bash
helm uninstall <release-name>
```

## Licence

Voir les licences individuelles de chaque chart pour plus de détails.
