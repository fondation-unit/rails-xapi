# frozen_string_literal: true

module XapiMiddleware
  class Configuration
    mattr_accessor :output_xapi_logs, :colored_xapi_logs

    def initialize
      @output_xapi_logs ||= true
      @colored_xapi_logs ||= true
    end
  end
end
