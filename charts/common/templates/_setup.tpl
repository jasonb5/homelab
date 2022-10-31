{{- define "common.setup" }}
{{ $newValues := mustMergeOverwrite .Values.common (omit .Values "common") }}
{{ $_ := set . "Values" $newValues }}
{{- end }}
