# frozen_string_literal: true
module Gcs
  class Scanner
    class << self
      def template_file
        File.join(Gcs.lib, 'template', "#{scanner_name}.tpl").to_s
      end

      private

      def scanner_name
        name.split('::').last.downcase
      end
    end
  end
end
