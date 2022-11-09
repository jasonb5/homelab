{{- define "common.pod" }}
{{- with .Values.affinity }}
affinity:
{{- toYaml . | nindent 2 }}
{{- end -}}
{{- $containers := dict (include "common.name" .) . }}
{{- with .Values.extraContainers }}
{{- range $key, $value := . }}
{{- $containers := mustMerge $containers (dict $key (dict "Values" $value "Release" $.Release "Chart" $.Chart)) }}
{{- end }}
{{- end }}
containers:
{{- range $key, $value := $containers }}
{{- $_ := set $value.Values "name" $key }}
{{- include "common.container" $value }}
{{- end }}
{{- with .Values.dnsConfig }}
dnsConfig:
{{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.dnsPolicy }}
dnsPolicy: {{ . }}
{{- end }}
{{- with .Values.hostNetwork }}
hostNetwork: {{ . }}
{{- end }}
{{- with .Values.initContainers }}
initContainers:
{{- range $key, $value := . }}
{{- $container := dict "Values" $value "Release" $.Release "Chart" $.Chart }}
{{- $_ := set $container.Values "name" $key }}
{{- include "common.container" $container }}
{{- end }}
{{- end }}
{{- with .Values.nodeName }}
nodeName: {{ . }}
{{- end }}
{{- with .Values.nodeSelector }}
nodeSelector:
{{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.runtimeClassName }}
runtimeClassName: {{ . }}
{{- end }}
{{- with .Values.podSecurityContext }}
securityContext:
{{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.serviceAccountName }}
serviceAccountName: {{ . }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
{{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.persistence }}
volumes:
{{- range $key, $value := . }}
{{- $type := default "emptyDir" $value.type }}
- name: {{ $key }}
  {{- if eq $type "configMap" }}
  configMap:
    name: {{ printf "%s-%s" (include "common.name" $) (default $key $value.name) }}
  {{- else if eq $type "emptyDir" }}
  emptyDir:
  {{- else if eq $type "hostPath" }}
  hostPath:
    path: {{ $value.path }}
  {{- else if eq $type "nfs" }}
  nfs:
    path: {{ $value.path }}
    {{- with $value.readOnly }}
    readOnly: {{. }}
    {{- end }}
    server: {{ $value.server }}
  {{- else if eq $type "pvc" }}
  persistentVolumeClaim:
    claimName: {{ printf "%s-%s" (include "common.name" $) (default $key $value.name) }}
    {{- with $value.readOnly }}
    readOnly: {{ . }}
    {{- end }}
  {{- else if eq $type "secret" }}
  secret:
    secretName: {{ printf "%s-%s" (include "common.name" $) (default $key $value.name) }}
  {{- else }}
  {{ fail (printf "%s is not valid, choose from: configMap, emptyDir, hostPath, nfs, pvc, secret" $value.type) }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}
