{{- $operatingSystem := printf "%s:%s" .Distro.Name .Distro.Version }}
{{- $image := .Source.Target.UserInput }}
{
  "version": "3.0.0",
  "vulnerabilities": [
  {{- $lastIndexOfMatches := getLastIndex .Matches}}
  {{- range $i, $_ := .Matches }}
    {
      "category": "container_scanning",
      "message": "{{ .Vulnerability.ID }} in {{ .Artifact.Name }}-{{ .Artifact.Version }}",
      "description": {{ .Vulnerability.Description | printf "%q" }},
      "cve": "{{ .Vulnerability.ID }}",
      "severity": {{ if eq .Vulnerability.Severity "Negligible" -}}
                    "Low" {{- /* Since GitLab lacks a 'negligible' severity, this was the closest value in meaning. */ -}}
                  {{- else -}}
                    "{{ .Vulnerability.Severity }}"
                  {{- end }},
      "confidence": "Unknown",
      "remediateMetadata": {{ if not .Vulnerability.FixedInVersion -}} {} {{- else -}}
      {
        "package_name": "{{ .Artifact.Name }}",
        "package_version": "{{ .Artifact.Version }}",
        "fixed_version": "{{ .Vulnerability.FixedInVersion }}",
        "summary": "Upgrade {{ .Artifact.Name }} to {{ .Vulnerability.FixedInVersion }}"
      }
      {{- end }},
      "solution": {{ if .Vulnerability.FixedInVersion -}}
                    "Upgrade {{ .Artifact.Name }} to {{ .Vulnerability.FixedInVersion }}"
                  {{- else -}}
                    "No solution provided"
                  {{- end }},
      "scanner": {
        "id": "grype",
        "name": "grype"
      },
      "location": {
        "dependency": {
          "package": {
            "name": "{{ .Artifact.Name }}"
          },
          "version": "{{ .Artifact.Version }}"
        },
        "operating_system": "{{ $operatingSystem }}",
        "image": "{{ $image }}"
      },
      "identifiers": [
        {{- if eq (slice .Vulnerability.ID 0 3) "CVE" }}
        {
          "type": "cve",
          "name": "{{ .Vulnerability.ID }}",
          "value": "{{ .Vulnerability.ID }}",
          "url": "https://nvd.nist.gov/vuln/detail/{{ .Vulnerability.ID }}"
        }
        {{- else if eq (slice .Vulnerability.ID 0 4) "GHSA" }}
        {
          "type": "ghsa",
          "name": "{{ .Vulnerability.ID }}",
          "value": "{{ .Vulnerability.ID }}",
          "url": "https://github.com/advisories/{{ .Vulnerability.ID }}"
        }
        {{- end }}
      ],
      "links": [
        {{- $lastIndexOfLinks := getLastIndex .Vulnerability.Links}}
        {{- range $j, $_ := .Vulnerability.Links }}
        {
          "url": "{{ . }}"
        }{{if ne $lastIndexOfLinks $j}},{{end}}
        {{- end }}
      ]
    }{{if ne $lastIndexOfMatches $i}},{{end}}
  {{- end }}
  ],
  "remediations": [],
  "scan": {
    "scanner": {
      "id": "grype",
      "name": "Grype",
      "url": "https://github.com/anchore/grype",
      "vendor": {
        "name": "Anchore"
      },
      "version": "0.12.1"
    },
    "type": "container_scanning",
    "start_time": "",
    "end_time": "",
    "status": "success"
  }
}
