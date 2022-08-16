# frozen_string_literal: true
module Gcs
  class LoggerFormatter
    COLOR_ESCAPES = {
      none: 0,
      bright: 1,
      black: 30,
      red: 31,
      green: 32,
      yellow: 33,
      blue: 34,
      magenta: 35,
      cyan: 36,
      white: 37,
      default: 39
    }.freeze

    LOG_LEVEL_COLOR = {
      ANY: :white,
      FATAL: :red,
      ERROR: :red,
      WARN: :yellow,
      INFO: :green,
      DEBUG: :blue
    }.freeze

    class << self
      def color(clr, text = nil)
        "\e[#{(COLOR_ESCAPES[clr] || 0)}m#{(text ? "#{text}\e[0m" : '')}"
      end

      def bc(clr, text = nil)
        "\e[#{((COLOR_ESCAPES[clr] || 0) + 10)}m#{(text ? "#{text}\e[0m" : '')}"
      end

      def formatter
        proc do |severity, datetime, progname, msg|
          # If the logger receives a nil message, then it sets the progname as the message.
          next if msg.blank? || msg == progname

          "[#{color(LOG_LEVEL_COLOR[severity.to_sym], severity)}] [#{datetime}] [#{progname}]  ▶  #{msg}\n"
        end
      end
    end
  end
end
