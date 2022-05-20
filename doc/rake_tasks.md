# Rake tasks for development

This page documents the Rake tasks inside the [Rakefile](../Rakefile), including what they do
and how to run them.

## Generate new Converter Fxitures

The [converter_spec](../spec/gcs/converter_spec.rb) tests its assertions against
fixture files location in [spec/fixtures/conveter](../spec/fixtures/converter/).

The fixtures inside the [`scanner_output/`](../spec/fixtures/converter/scanner_output/) directory represent the raw output of
a scanner which is passed to `Converter#convert`. The fixtures inside [`expect/`](../spec/fixtures/converter/expect/)
represent the expected output of `Converter#convert` for each given input file.

All of the files inside `expect/` can be automatically generated using the `generate_converter_fixtures`
rake task. To run this task:

```shell
bundle exec rake generate_converter_fixtures
```

These fixtures should be regenerated whenever one of the input files inside
[`scanner_output/`](../spec/fixtures/converter/scanner_output/) is changed,
or whenever the expected output of `Converter#convert` changes.
