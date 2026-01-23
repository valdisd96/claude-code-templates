{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "chart.fullname" -}}
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
{{- define "chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "chart.labels" -}}
helm.sh/chart: {{ include "chart.chart" . }}
{{ include "chart.selectorLabels" . }}
{{ include "chart.extraLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Some extra labels
*/}}
{{- define "chart.extraLabels" -}}
{{- if hasKey .Values "moniringEnable" }}
moniring_enable: {{ .Values.moniringEnable | quote }}
{{- end }}
{{- end }}

{{- define "chart-jobs.labels" -}}
helm.sh/chart: {{ include "chart.chart" . }}
{{ include "chart-jobs.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Custom labels for configmaps and secrets
*/}}
{{- define "chart.labelsConfigmapSecret" -}}
{{ include "chart.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "chart.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "chart.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
Create secret for authentification in Docker registry Prod
*/}}
{{- define "imagePullSecret" }}
{{- printf "{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}" .Values.image.registry (printf "%s:%s" .Values.image.username .Values.image.password | b64enc) | b64enc }}
{{- end }}


{{/*
Create secret for authentification in Docker registry Dev
*/}}
{{- define "imagePullSecretDev" }}
{{- printf "{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}" .Values.imageDev.registry (printf "%s:%s" .Values.imageDev.username .Values.imageDev.password | b64enc) | b64enc }}
{{- end }}

{{- define "kafkaTopicsNaming" }}
{{- if not (hasPrefix "prod" .Release.Namespace) }}{{ .Release.Namespace }}.{{- end }}
{{- end }}

{{/*
Database username and database name itself
*/}}
{{- define "chart.db_username" -}}
{{- if .Values.database.main.user }}
{{- .Values.database.main.user }}
{{- else }}
{{- printf "%s-%s-user" .Release.Namespace .Values.appConfig.appName }}
{{- end }}
{{- end }}

{{- define "chart.db_name" -}}
{{- if .Values.database.main.name }}
{{- .Values.database.main.name }}
{{- else }}
{{- printf "%s-%s-db"  .Release.Namespace .Values.appConfig.appName }}
{{- end }}
{{- end }}

{{- define "chart.db_click_username" -}}
{{- if .Values.database.clickhouse.user }}
{{- .Values.database.clickhouse.user }}
{{- else }}
{{- printf "%s_%s_click_user" (replace "-" "_" .Release.Namespace) (replace "-" "_" .Values.appConfig.appName) }}
{{- end }}
{{- end }}

{{- define "chart.db_click_name" -}}
{{- if .Values.database.clickhouse.name }}
{{- .Values.database.clickhouse.name }}
{{- else }}
{{- printf "%s_%s_click_db"  (replace "-" "_" .Release.Namespace) (replace "-" "_" .Values.appConfig.appName) }}
{{- end }}
{{- end }}