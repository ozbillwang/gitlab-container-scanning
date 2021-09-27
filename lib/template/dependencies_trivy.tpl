{{- range . }}
{
  "dependency_files": {
    "path": "Dockerfile",
    "package_manager": "{{ .Type }}",
    "dependencies": [
{{- $t_first := true }}
{{- $target := .Target }}
  {{- range .Packages -}}
    {{- if $t_first -}}
      {{- $t_first = false -}}
    {{ else -}}
      ,
    {{- end }}
      {
        "{{ .SrcName }}": " {{ .SrcVersion }}"
      }
  {{- end }}
{{- end }}
    ]
  }
}

