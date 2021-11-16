{
  "version": "14.0.3",
  "scan": {
    "type": "dependency_scanning",
    "start_time": "",
    "end_time": "",
    "status": "success",
    "scanner": {
      "id": "trivy",
      "name": "Trivy",
      "url": "https://github.com/aquasecurity/trivy/",
      "vendor": {
        "name": "GitLab"
      },
      "version": "0.20.2"
    },
    "analyzer": {
      "id": "gcs",
      "name": "GitLab Container Scanning",
      "vendor": {
        "name": "GitLab"
      },
      "version": "$gcsVersion"
    }
  },
  "vulnerabilities": [],
  "dependency_files": [
    {{- $t_first_result := true }}
    {{- range . }}
    {{- if eq .Class "os-pkgs" }}
    {{- if $t_first_result -}}
      {{- $t_first_result = false -}}
    {{ else -}}
      ,
    {{- end }}
    {
      "path": "Dockerfile",
      "package_manager": "{{ .Type }}",
      "dependencies": [
      {{- $t_first := true }}
      {{- range .Packages -}}
        {{- if $t_first -}}
          {{- $t_first = false -}}
        {{ else -}}
          ,
        {{- end }}
        {
          "package": {
            "name": "{{ .SrcName }}"
          },
          "version": "{{ .SrcVersion }}"
        }
      {{- end }}
      ]
    }
    {{- end }}
    {{- end }}
  ]
}
