{{/*
Expand the name of the chart.
*/}}
{{- define "remote-cluster-nosudo.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "remote-cluster-nosudo.fullname" -}}
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
{{- define "remote-cluster-nosudo.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "remote-cluster-nosudo.labels" -}}
helm.sh/chart: {{ include "remote-cluster-nosudo.chart" . }}
{{ include "remote-cluster-nosudo.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "remote-cluster-nosudo.selectorLabels" -}}
app.kubernetes.io/name: {{ include "remote-cluster-nosudo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the cluster
*/}}
{{- define "cluster.name" -}}
{{- .Values.cluster.name | default .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the name of the remote machine template
*/}}
{{- define "remotemachinetemplate.name" -}}
{{- printf "%s-rmt" (include "cluster.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the name of the remote cluster
*/}}
{{- define "remotecluster.name" -}}
{{- include "cluster.name" . }}
{{- end }}

{{/*
Create the name of the k0s control plane
*/}}
{{- define "k0scontrolplane.name" -}}
{{- printf "%s-cp" (include "cluster.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the name of the k0s worker config template
*/}}
{{- define "k0sworkerconfigtemplate.name" -}}
{{- printf "%s-wct" (include "cluster.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the name of the machine deployment
*/}}
{{- define "machinedeployment.name" -}}
{{- printf "%s-md" (include "cluster.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Generate k0s systemd service for root user
*/}}
{{- define "k0s.systemd.service" -}}
[Unit]
Description=k0s - Zero Friction Kubernetes
Documentation=https://k0sproject.io
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
User=root
Group=root
ExecStart={{ .Values.machineConfig.paths.k0sBinary }} worker --config={{ .Values.machineConfig.paths.k0sConfig }}/k0s.yaml
Restart=always
RestartSec=5
KillMode=process
TimeoutStopSec=300
OOMScoreAdjust=-999
Delegate=yes
LimitNOFILE=1048576
LimitNPROC=1048576
LimitCORE=infinity
TasksMax=infinity

[Install]
WantedBy=multi-user.target
{{- end }}
