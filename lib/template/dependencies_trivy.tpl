{{- range . }}
{
  "version": "14.0.3",
  "type": "dependency_scanning",
  "start_time": "",
  "end_time": "",
  "status": "success",
  "vulnerabilities": [],
  "scan": {
    "scanner": {
      "id": "trivy",
      "name": "Trivy",
      "url": "https://github.com/aquasecurity/trivy/",
      "vendor": {
        "name": "GitLab"
      },
      "version": "0.19.2"
    }
  },
  "analyzer": {
    "id": "gcs",
    "name": "GitLab Container Scanning",
    "vendor": {
      "name": "GitLab"
    },
    "version": "0.0.0"
  },
  "dependency_files": [
    {
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
        "{{ .SrcName }}": "{{ .SrcVersion }}"
        }
      {{- end }}
      {{- end }}
      ]
    }
  ]
}
