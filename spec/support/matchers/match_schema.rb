# frozen_string_literal: true

RSpec::Matchers.define :match_schema do |report_type|
  def schema_for(type)
    relative_path = "spec/schemas/dist/#{type.tr('_', '-')}-report-format.json"
    JSONSchemer.schema(Pathname.pwd.join(relative_path))
  end

  def validate(type, data)
    schema_for(type).validate(data).map { |error| JSONSchemer::Errors.pretty(error) }
  end

  match do |actual|
    !actual.nil? && (@errors = validate(report_type.to_s, actual.to_h)).empty?
  end

  failure_message do |response|
    "didn't match the schema for #{report_type}" \
    " The validation errors were:\n#{@errors.join("\n")}"
  end
end
