{{- define "common.app" }}
{{- include "common.setup" . }}
{{- include "common.vpn" . }}

{{- range (concat (list .Values) .Values.extraWorkloads) }}
---
{{- if eq .type "deployment" }}
{{- include "common.deployment" (dict "Values" . "Release" $.Release "Chart" $.Chart) }}
{{- else }}
{{ fail (printf "%s is not valid" .type) }}
{{- end }}

{{- with .persistence }}
{{- range $key, $value := . }}
{{- if eq $value.type "pvc" }}
---
{{ include "common.pvc" (dict "Values" $value "Release" $.Release "Chart" $.Chart) }}
{{- end }}
{{- end }}
{{- end }}

{{- with .ingress }}
{{- range $key, $value := . }}
---
{{- $service := get $.Values.services $key }}
{{ include "common.ingress" (dict "Values" $value "name" $key "service" $service "Release" $.Release "Chart" $.Chart) }}
{{- end }}
{{- end }}

{{- end }}

{{- with .Values.configMaps }}
{{- range $key, $value := . }}
---
{{- include "common.configMap" (dict "name" $key "Values" $value "Release" $.Release "Chart" $.Chart) }}
{{- end }}
{{- end }}

{{- with .Values.secrets }}
{{- range $key, $value := . }}
---
{{- include "common.secret" (dict "name" $key "Values" $value "Release" $.Release "Chart" $.Chart) }}
{{- end }}
{{- end }}

{{- with .Values.extraObjects }}
{{- range . }}
---
{{- tpl . $ }}
{{- end }}
{{- end }}
{{- end }}
