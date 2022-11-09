{{- define "common.service" }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ printf "%s-%s" (include "common.name" .) .name }}
  namespace: {{ .Release.Namespace }}
  {{- with .Values.annotations }}
  annotations:
  {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- $commonLabels := include "common.labels" . | fromYaml }}
  {{- $labels := mustMerge $commonLabels (default dict .Values.labels) }}
  labels: {{- toYaml $labels | nindent 4 }}
spec:
  ports:
    - name: {{ .name }}
      port: {{ .Values.port }}
      protocol: {{ default "TCP" .Values.protocol }}
  type: {{ default "ClusterIP" .Values.type }}
  selector: {{- include "common.selectorLabels" . | nindent 4 }}
{{- end }}
