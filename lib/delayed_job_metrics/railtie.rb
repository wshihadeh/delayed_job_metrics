# frozen_string_literal: true

module DelayedJobMetrics
  # The Railtie triggering a setup from RAILs to make it configurable
  class Railtie < ::Rails::Railtie
    initializer 'delayed_jobs_metrics.insert_middleware' do
      config.delayed_jobs_metrics = ::ActiveSupport::OrderedOptions.new
      config.delayed_jobs_metrics.path =
        ENV.fetch('DELAYED_JOB_METRICS_ENNDPOINT', '/metrics')

      config.app_middleware.insert_after(
        ActionDispatch::RequestId,
        DelayedJobMetrics::Exporter,
        config.delayed_jobs_metrics
      )
    end
  end
end
