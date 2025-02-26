{{/*
Expand the name of the chart.
*/}}
{{- define "intrexx-portal.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "intrexx-portal.fullname" -}}
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
{{- define "intrexx-portal.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "intrexx-portal.labels" -}}
helm.sh/chart: {{ include "intrexx-portal.chart" . }}
{{ include "intrexx-portal.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "intrexx-portal.selectorLabels" -}}
app.kubernetes.io/name: {{ include "intrexx-portal.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "intrexx-portal.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "intrexx-portal.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Database host
*/}}
{{- define "intrexx-portal.databaseHost" -}}
{{- if .Values.postgresql.enabled }}
{{- printf "%s-postgresql" (include "intrexx-portal.fullname" .) }}
{{- else }}
{{- .Values.externalDatabase.host }}
{{- end }}
{{- end }}

{{/*
Database port
*/}}
{{- define "intrexx-portal.databasePort" -}}
{{- if .Values.postgresql.enabled }}
{{- printf "5432" }}
{{- else }}
{{- .Values.externalDatabase.port | toString }}
{{- end }}
{{- end }}

{{/*
Database name
*/}}
{{- define "intrexx-portal.databaseName" -}}
{{- if .Values.postgresql.enabled }}
{{- .Values.postgresql.auth.database }}
{{- else }}
{{- .Values.externalDatabase.database }}
{{- end }}
{{- end }}

{{/*
Database user
*/}}
{{- define "intrexx-portal.databaseUser" -}}
{{- if .Values.postgresql.enabled }}
{{- .Values.postgresql.auth.username }}
{{- else }}
{{- .Values.externalDatabase.user }}
{{- end }}
{{- end }}

{{/*
Database secret name
*/}}
{{- define "intrexx-portal.databaseSecretName" -}}
{{- if .Values.postgresql.enabled }}
{{- printf "%s-postgresql" (include "intrexx-portal.fullname" .) }}
{{- else }}
{{- printf "%s-external-db" (include "intrexx-portal.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Database secret key
*/}}
{{- define "intrexx-portal.databaseSecretKey" -}}
{{- if .Values.postgresql.enabled }}
{{- printf "password" }}
{{- else }}
{{- printf "db-password" }}
{{- end }}
{{- end }}

{{/*
Solr host
*/}}
{{- define "intrexx-portal.solrHost" -}}
{{- if .Values.solr.enabled }}
{{- printf "%s-solr" (include "intrexx-portal.fullname" .) }}
{{- else if .Values.zookeeper.enabled }}
{{- printf "%s-zookeeper" (include "intrexx-portal.fullname" .) }}
{{- else }}
{{- printf "zookeeper" }}
{{- end }}
{{- end }}

{{/*
Solr port
*/}}
{{- define "intrexx-portal.solrPort" -}}
{{- if .Values.solr.enabled }}
{{- printf "8983" }}
{{- else }}
{{- printf "2181" }}
{{- end }}
{{- end }}

{{/*
Solr user
*/}}
{{- define "intrexx-portal.solrUser" -}}
{{- if .Values.solr.enabled }}
{{- .Values.solr.authentication.adminUsername }}
{{- else }}
{{- printf "solr" }}
{{- end }}
{{- end }}

{{/*
Solr secret name
*/}}
{{- define "intrexx-portal.solrSecretName" -}}
{{- if .Values.solr.enabled }}
{{- printf "%s-solr" (include "intrexx-portal.fullname" .) }}
{{- else }}
{{- printf "%s-external-solr" (include "intrexx-portal.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Solr secret key
*/}}
{{- define "intrexx-portal.solrSecretKey" -}}
{{- if .Values.solr.enabled }}
{{- printf "solr-password" }}
{{- else }}
{{- printf "solr-password" }}
{{- end }}
{{- end }}
