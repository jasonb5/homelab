{{- define "common.deployment" }}
apiVersion: apps/v1
kind: Deployment
metadata:
  {{- if .Values.name }}
  name: {{ printf "%s-%s" (include "common.name" .) .Values.name }}
  {{- else }}
  name: {{ include "common.name" . }}
  {{- end }}
  namespace: {{ .Release.Namespace }}
  {{- with .Values.annotations }}
  annotations:
  {{- toYaml . | nindent 4 }}
  {{- end }}
  labels:
  {{- mustMerge (include "common.labels" . | fromYaml) (default dict .Values.labels) | toYaml | nindent 4 }}
spec:
  replicas: {{ default 1 .Values.replicas }}
  selector:
    matchLabels:
    {{- include "common.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
      {{- include "common.selectorLabels" . | nindent 8 }}
    spec:
    {{- include "common.pod" . | nindent 6 }}
{{- end }}
