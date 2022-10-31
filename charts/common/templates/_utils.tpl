{{- define "common.debug_vars" }}
{{ . | mustToPrettyJson | printf "%s" | fail }}
{{- end }}
