# frozen_string_literal: true

module Status
  module_function

  # done is similar to the Ruby built-in `abort`,
  # except it exits with status code 0.
  def done(message)
    puts message
    exit 0
  end
end
