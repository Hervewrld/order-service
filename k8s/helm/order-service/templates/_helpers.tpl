{{- define "order-service.fullname" -}}
{{ .Release.Name }}
{{- end -}}

{{- define "order-service.labels" -}}
app.kubernetes.io/part-of: order-service
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
