{{- define "common.container" }}
- name: {{ .Values.name }}
  {{- with .Values.args }}
  args:
  {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.command }}
  command:
  {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.env }}
  env:
  {{- range $key, $value := . }}
  - name: {{ $key }}
    {{- if kindIs "string" $value }}
    value: {{ toYaml $value }}
    {{- else }}
    valueFrom:
      {{- if eq $value.type "configMap" }}
      configMapKeyRef:
        key: {{ $key }}
        name: {{ printf "%s-%s" (include "common.name" $) $value.name }}
      {{- else if eq $value.type "secret" }}
      secretKeyRef:
        key: {{ $key }}
        name: {{ printf "%s-%s" (include "common.name" $) $value.name }}
      {{- else }}
      {{ fail "Valid values for 'type': configMap, secret" }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- end }}
  {{- with .Values.envFrom }}
  envFrom:
  {{- range . }}
  {{- if eq .type "configMap" }}
  - configMapRef:
  {{- else if eq .type "secret" }}
  - secretRef:
  {{- else }}
  {{ fail "Valid values for 'type': configMap, secret" }}
  {{- end }}
      name: {{ printf "%s-%s" (include "common.name" $) .name }}
  {{- end }}
  {{- end }}
  {{- with .Values.image }}
  image: {{ .repository }}:{{ .tag }}
  {{- with .pullPolicy }}
  imagePullPolicy: {{ . }}
  {{- end }}
  {{- end }}
  {{- with .Values.livenessProbe }}
  livenessProbe:
  {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.services }}
  ports:
  {{- range $key, $value := . }}
  - containerPort: {{ $value.port }}
    {{- with $value.hostPort }}
    hostPort: {{ . }}
    {{- end }}
    name: {{ $key }}
    {{- with $value.protocol }}
    protocol: {{ . }}
    {{- end }}
  {{- end }}
  {{- end }}
  {{- with .Values.readinessProbe }}
  readinessProbe:
  {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.resources }}
  resources:
  {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.securityContext }}
  securityContext: 
  {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.persistence }}
  volumeMounts:
  {{- range $key, $value := . }}
  {{- if or (not (hasKey $value "unique")) (eq (get $value "unique") $.Values.name) }}
  - mountPath: {{ default (printf "/%s" $key) $value.mountPath }}
    name: {{ $key }}
    {{- with $value.readOnly }}
    readOnly: {{ . }}
    {{- end }}
    {{- with $value.subPath }}
    subPath: {{ . }}
    {{- end }}
  {{- end }}
  {{- end }}
  {{- end }}
{{- end }}
