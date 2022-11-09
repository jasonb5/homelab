{{- define "common.vpn" }}
{{- if .Values.sidecars.vpn.enabled }}
{{- $vpnSecret := dict "vpn" (dict "vpn.auth" .Values.sidecars.vpn.auth "vpn.conf" .Values.sidecars.vpn.configFile) }}
{{- $_ := mustMerge .Values.secrets $vpnSecret }}

{{- $vpnPersistence := dict "vpn-config" (dict "type" "secret" "mountPath" "/vpn/vpn.conf" "subPath" "vpn.conf" "name" "vpn" "unique" "openvpn" "enabled" "true") }}
{{- $_ := mustMerge $vpnPersistence (dict "vpn-auth" (dict "type" "secret" "mountPath" "/vpn/vpn.auth" "subPath" "vpn.auth" "name" "vpn" "unique" "openvpn" "enabled" "true")) }}
{{- if not .Values.sidecars.vpn.persistence }}
{{- $_ := set .Values.sidecars.vpn "persistence" $vpnPersistence }}  
{{- else }}
{{- $_ := mustMerge .Values.sidecars.vpn.persistence $vpnPersistence }}
{{- end }}
{{- $_ := mustMerge .Values.persistence $vpnPersistence }}
{{- $_ := mustMerge .Values.extraContainers (dict "openvpn" .Values.sidecars.vpn) }}
{{- end }}
{{- end }}
