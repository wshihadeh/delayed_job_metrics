# frozen_string_literal: true

module DelayedJobMetrics
  #:nodoc:
  class BasicAuth < ::Rack::Auth::Basic
    def call(env, callback)
      auth = ::Rack::Auth::Basic::Request.new(env)

      return unauthorized unless auth.provided?
      return bad_request unless auth.basic?
      return callback.call(env) if valid?(auth)

      unauthorized
    end
  end
end
