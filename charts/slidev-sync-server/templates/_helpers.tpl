{{- define "slidev-sync-server.name" -}}
{{- printf "%s-slidev-sync-server" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- define "slidev-sync-server.selector" -}}
app.kubernetes.io/name: slidev-sync-server
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end -}}
{{- define "slidev-sync-server.labels" -}}
{{ include "slidev-sync-server.selector" . }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | quote }}
{{- end -}}
