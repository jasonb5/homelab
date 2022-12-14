{{- define "common.app" }}
{{- include "common.setup" . }}
{{- include "common.vpn" . }}
{{- include "common.codeserver" . }}

{{- range (concat (list .Values) .Values.extraWorkloads) }}

{{- if eq .type "deployment" }}
{{- include "common.deployment" (dict "Values" . "Release" $.Release "Chart" $.Chart) }}
{{- end }}

{{- with .persistence }}
{{- range $key, $value := . }}
{{ include "common.pvc" (dict "Values" $value "name" $key "Release" $.Release "Chart" $.Chart) }}
{{- end }}
{{- end }}

{{- with .services }}
{{- range $key, $value := . }}
{{ include "common.service" (dict "Values" $value "name" $key "Release" $.Release "Chart" $.Chart) }}
{{- end }}
{{- end }}

{{- with .ingress }}
{{- range $key, $value := . }}
{{- $service := get $.Values.services $key }}
{{ include "common.ingress" (dict "Values" $value "name" $key "service" $service "Release" $.Release "Chart" $.Chart) }}
{{- end }}
{{- end }}

{{- end }}

{{- with .Values.configMaps }}
{{- range $key, $value := . }}
{{- include "common.configMap" (dict "name" $key "Values" $value "Release" $.Release "Chart" $.Chart) }}
{{- end }}
{{- end }}

{{- with .Values.secrets }}
{{- range $key, $value := . }}
{{- include "common.secret" (dict "name" $key "Values" $value "Release" $.Release "Chart" $.Chart) }}
{{- end }}
{{- end }}

{{- with .Values.extraObjects }}
{{- range . }}
---
{{ if typeIs "string" . }}
{{- tpl . $ }}
{{- else }}
{{- tpl (. | toYaml) $ }}
{{- end }}
{{- end }}
{{- end }}

{{- with .Values.extraObjects2 }}
{{- range . }}
---
{{ if typeIs "string" . }}
{{- tpl . $ }}
{{- else }}
{{- tpl (. | toYaml) $ }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
