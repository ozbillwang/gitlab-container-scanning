# frozen_string_literal: true
require 'support/proxy_server'

module ProxyHelper
  def x509_certificate
    Gcs.root.join('tmp/wildcard.test.crt')
  end
end
