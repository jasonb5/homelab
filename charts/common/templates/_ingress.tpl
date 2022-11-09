{{- define "common.ingress" }}
{{- if .Values.enabled }}
---
apiVersion: networking.k8s.io/v1
kind: Ingress
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
spec:
  {{- with .Values.ingressClassName }}
  ingressClassName: {{ . }}
  {{- end }}
  rules:
  - http:
      paths:
      {{- $paths := default (list (dict "path" "/")) .Values.paths }}
      {{- range $paths }}
      - path: {{ .path }}
        {{- with .host }}
        host: {{ . }}
        {{- end }}
        {{- with .pathType }}
        pathType: {{ . }}
        {{- end }}
        backend:
          service:
            name: {{ printf "%s-%s" (include "common.name" $) $.name }}
            port:
              number: {{ $.service.port }}
      {{- end }}
  {{- with .Values.tls }}
  tls:
    - secretName: {{ printf "%s-%s" (include "common.name" $) $.name }}
  {{- end }}
{{- end }}
{{- end }}
