# frozen_string_literal: true
module Gcs
  class Util
    class << self
      def measure_runtime
        start_time = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
        yield
        end_time = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
        { start_time: start_time, end_time: end_time }
      end

      def write_file(name = Gcs::DEFAULT_REPORT_NAME, content = nil)
        full_path = Pathname.pwd.join(name)
        Gcs.logger.debug("writing results to #{full_path}")
        FileUtils.mkdir_p(full_path.dirname)
        IO.write(full_path, block_given? ? yield : content)
      end
    end
  end
end
