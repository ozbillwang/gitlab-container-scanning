{{- /* Copyright (c) 2020-present Manuel Rüger

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

Template copied from https://github.com/aquasecurity/trivy/blob/712f9eba35999cfa6ba982a620bdd4866e8f40a2/contrib/gitlab.tpl

 */ -}}
{
  "version": "3.0.0",
  "vulnerabilities": [
  {{- $t_first := true }}
  {{- range . }}
  {{- $target := .Target }}
    {{- range .Vulnerabilities -}}
    {{- if $t_first -}}
      {{- $t_first = false -}}
    {{ else -}}
      ,
    {{- end }}
    {
      "category": "container_scanning",
      "message": "{{ printf "%s in %s-%s" .VulnerabilityID .PkgName .InstalledVersion }}",
      "description": {{ .Description | printf "%q" }},
      {{- /* cve is a deprecated key, use id instead */}}
      "cve": "{{ .VulnerabilityID }}",
      "severity": {{ if eq .Severity "UNKNOWN" -}}
                    "Unknown"
                  {{- else if eq .Severity "LOW" -}}
                    "Low"
                  {{- else if eq .Severity "MEDIUM" -}}
                    "Medium"
                  {{- else if eq .Severity "HIGH" -}}
                    "High"
                  {{- else if eq .Severity "CRITICAL" -}}
                    "Critical"
                  {{-  else -}}
                    "{{ .Severity }}"
                  {{- end }},
      {{- /* TODO: Define confidence */}}
      "confidence": "Unknown",
      {{- /* this is added for easy conversion */ -}}
      "remediateMetadata": {{ if .FixedVersion -}}
            { "package_name": "{{ .PkgName }}",
              "package_version": "{{.InstalledVersion}}",
              "fixed_version": "{{ .FixedVersion }}",
              "summary": "Upgrade {{ .PkgName }} to {{ .FixedVersion }}"
            {{- else -}}
              {
            {{- end }}
      },
      {{- /* this is added for easy conversion */ -}}
      "solution": {{ if .FixedVersion -}}
                    "Upgrade {{ .PkgName }} to {{ .FixedVersion }}"
                  {{- else -}}
                    "No solution provided"
                  {{- end }},
      "scanner": {
        "id": "trivy",
        "name": "trivy"
      },
      "location": {
        "dependency": {
          "package": {
            "name": "{{ .PkgName }}"
          },
          "version": "{{ .InstalledVersion }}"
        },
        {{- /* TODO: No mapping available - https://github.com/aquasecurity/trivy/issues/332 */}}
        "operating_system": "Unknown",
        "image": "{{ $target }}"
      },
      "identifiers": [
        {
	  {{- /* TODO: Type not extractable - https://github.com/aquasecurity/trivy-db/pull/24 */}}
          "type": "cve",
          "name": "{{ .VulnerabilityID }}",
          "value": "{{ .VulnerabilityID }}",
          "url": ""
        }
      ],
      "links": [
        {{- $l_first := true -}}
        {{- range .References -}}
        {{- if $l_first -}}
          {{- $l_first = false }}
        {{- else -}}
          ,
        {{- end -}}
        {
          "url": "{{ . }}"
        }
        {{- end }}
      ]
    }
    {{- end -}}
  {{- end }}
  ],
  "remediations": [],
  "scan": {
  "scanner": {
    "id": "trivy",
    "name": "Trivy",
    "url": "https://github.com/aquasecurity/trivy/",
    "vendor": {
      "name": "GitLab"
    },
    "version": "0.19.1"
  },
  "type": "container_scanning",
  "start_time": "",
  "end_time": "",
  "status": "success"
  }
}
