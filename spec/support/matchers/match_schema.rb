# frozen_string_literal: true

RSpec::Matchers.define :match_schema do |report_type|
  def schema_for(type)
    relative_path = "spec/schemas/dist/#{type.tr('_', '-')}-report-format.json"
    json = JSON.parse(Pathname.pwd.join(relative_path).read)
    json.delete('$schema')
    json
  end

  match do |actual|
    !actual.nil? && (@errors = JSON::Validator.fully_validate(schema_for(report_type.to_s), actual.to_h)).empty?
  end

  failure_message do |response|
    "didn't match the schema for #{report_type}" \
    " The validation errors were:\n#{@errors.join("\n")}"
  end
end
