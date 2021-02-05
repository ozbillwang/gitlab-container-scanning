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
    }

    LOG_LEVEL_COLOR = {
      UNKNOWN: :white,
      FATAL: :red,
      ERROR: :red,
      WARN: :yellow,
      INFO: :green,
      DEBUG: :blue
    }

    class << self
      def color(clr, text = nil)
        "\x1B[" + (COLOR_ESCAPES[clr] || 0).to_s + 'm' +
          (text ? text + "\x1B[0m" : '')
      end

      def bc(clr, text = nil)
        "\x1B[" + ((COLOR_ESCAPES[clr] || 0) + 10).to_s + 'm' +
          (text ? text + "\x1B[0m" : '')
      end

      def formatter
        Proc.new do |severity, datetime, progname, msg|
          "[#{color(LOG_LEVEL_COLOR[severity.to_sym], severity)}] [Trivy] [#{datetime}] [#{progname}]  ▶  #{msg}\n"
        end
      end
    end
  end
end
