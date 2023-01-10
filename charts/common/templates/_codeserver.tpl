{{- define "common.codeserver" }}
{{- if .Values.sidecars.codeserver.enabled }}
{{- $_ := mustMerge .Values.services .Values.sidecars.codeserver.services }}
{{- $_ := mustMerge .Values.sidecars.codeserver.persistence .Values.persistence }}
{{- $_ := mustMerge .Values.extraContainers (dict "codeserver" .Values.sidecars.codeserver) }}
{{- end }}
{{- end }}
