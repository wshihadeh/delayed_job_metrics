# frozen_string_literal: true

require 'delayed_job_metrics/version'
require 'prometheus/middleware/exporter'
require 'delayed_job_metrics/exporter'
require 'delayed_job_metrics/railtie' if defined?(Rails)

module DelayedJobMetrics
  class Error < StandardError; end
end
