# frozen_string_literal: true
require 'rspec/expectations'

module ExitCodeMatchers
  extend RSpec::Matchers::DSL
  RSpec::Matchers.define :terminate do |code|
    actual = nil

    def supports_block_expectations?
      true
    end

    match do |block|
      begin
        block.call
      rescue SystemExit => e
        actual = e.status
      end
      actual && (actual == status_code)
    end

    chain :with_code do |status_code|
      @status_code = status_code
    end

    failure_message do |block|
      "expected block to call exit(#{status_code}) but exit" +
        (actual.nil? ? " not called" : "(#{actual}) was called")
    end

    failure_message_when_negated do |block|
      "expected block not to call exit(#{status_code})"
    end

    description do
      "expect block to call exit(#{status_code})"
    end

    def status_code
      @status_code ||= 0
    end
  end
end
