{{- define "common.configMap" }}
apiVersion: v1
kind: ConfigMap
metdata:
  name: {{ printf "%s-%s" (include "common.name" .) .name }}
  namespace: {{ .Release.Namespace }}
  {{- with .Values.annotations }}
  annotations:
  {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- $commonLabels := include "common.labels" . | fromYaml }}
  {{- $labels := mustMerge $commonLabels (default dict .Values.labels) }}
  labels:
  {{- toYaml . | nindent 4 }}
data:
{{- toYaml .Values | nindent 2 }}
{{- end }}
