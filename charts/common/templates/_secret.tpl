{{- define "common.secret" }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ printf "%s-%s" (include "common.name" .) .name }}
  namespace: {{ .Release.Namespace }}
  {{- with .Values.annotations }}
  annotations:
  {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- $commonLabels := include "common.labels" . | fromYaml }}
  {{- $labels := mustMerge $commonLabels (default dict .Values.labels) }}
  labels:
  {{- toYaml $labels | nindent 4 }}
type: Opaque
data:
  {{- range $key, $value := .Values }}
  {{ printf "%s: %s" $key ($value | b64enc) }}
  {{- end }}
{{- end }}
