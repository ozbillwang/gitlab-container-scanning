{{- /* Copyright (c) 2020-present Manuel Rüger

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

Template copied from https://github.com/aquasecurity/trivy/blob/712f9eba35999cfa6ba982a620bdd4866e8f40a2/contrib/gitlab.tpl

 */ -}}

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

