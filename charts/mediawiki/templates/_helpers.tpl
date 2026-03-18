{{/*
Expand the name of the chart.
*/}}
{{- define "mediawiki.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "mediawiki.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "mediawiki.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mediawiki.labels" -}}
helm.sh/chart: {{ include "mediawiki.chart" . }}
{{ include "mediawiki.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mediawiki.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mediawiki.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
MariaDB host (internal or external)
*/}}
{{- define "mediawiki.mariadbHost" -}}
{{- if .Values.mariadb.internal.enabled -}}
{{- printf "%s-mariadb" (include "mediawiki.fullname" .) }}
{{- else -}}
{{- .Values.mariadb.external.host }}
{{- end }}
{{- end }}

{{/*
MariaDB port
*/}}
{{- define "mediawiki.mariadbPort" -}}
{{- if .Values.mariadb.internal.enabled -}}
3306
{{- else -}}
{{- .Values.mariadb.external.port | default 3306 }}
{{- end }}
{{- end }}

{{/*
MariaDB database name
*/}}
{{- define "mediawiki.mariadbDatabase" -}}
{{- if .Values.mariadb.internal.enabled -}}
{{- .Values.mariadb.internal.database }}
{{- else -}}
{{- .Values.mariadb.external.database }}
{{- end }}
{{- end }}

{{/*
MariaDB user
*/}}
{{- define "mediawiki.mariadbUser" -}}
{{- if .Values.mariadb.internal.enabled -}}
{{- .Values.mariadb.internal.user }}
{{- else -}}
{{- .Values.mariadb.external.user }}
{{- end }}
{{- end }}
