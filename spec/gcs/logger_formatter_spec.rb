# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gcs::LoggerFormatter do
  let(:logger_timestamp) { Time.new(2001, 2, 3, 4, 5, 6, "+0000") }
  let(:message) { "The tanuki is native to Japan" }

  subject(:emit) do
    # We must initalize the logger within the block, because the
    # output matcher cannot intercept stdout if the logger was
    # initialized beforehand.
    logger = Logger.new($stdout, progname: 'container-scanning')
    logger.formatter = described_class.formatter
    logger.public_send(severity, message)
  end

  before do
    allow(Time).to receive(:now).and_return(logger_timestamp)
  end

  shared_examples 'log message' do
    it 'logs message in expected format' do
      expected_log_level = "[\e[#{expected_color_code}m#{expected_severity}\e[0m]"
      expected_timestamp = "[2001-02-03 04:05:06 +0000]"
      expected_progname = "[container-scanning]"
      expected_stdout = "#{expected_log_level} #{expected_timestamp} #{expected_progname}  >  #{message}\n"

      expect { emit }.to output(expected_stdout).to_stdout
    end

    context 'when message is blank' do
      let(:message) { '' }

      it 'does not log message' do
        expect { emit }.not_to output.to_stdout
      end
    end

    context 'when message is nil' do
      let(:message) { nil }

      it 'does not log message' do
        expect { emit }.not_to output.to_stdout
      end
    end
  end

  describe 'log levels' do
    using RSpec::Parameterized::TableSyntax

    where(:severity, :expected_severity, :expected_color_code) do
      :unknown | 'ANY'   | '37'
      :fatal   | 'FATAL' | '31'
      :error   | 'ERROR' | '31'
      :warn    | 'WARN'  | '33'
      :info    | 'INFO'  | '32'
      :debug   | 'DEBUG' | '34'
    end

    with_them do
      it_behaves_like 'log message'
    end
  end
end
