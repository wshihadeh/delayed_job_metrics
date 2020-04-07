# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength, Metrics/ClassLength, Metrics/AbcSize
module DelayedJobMetrics
  # :nodoc:
  class Exporter < Prometheus::Middleware::Exporter
    def initialize(app, options = {})
      @app = app
      @registry = options[:registry] || Prometheus::Client.registry
      @path = options[:path] || '/metrics'
      @acceptable = build_dictionary(FORMATS, FALLBACK)

      init_delayed_jobs_metrics
    end

    def call(env)
      if env['PATH_INFO'] == @path
        format = negotiate(env, @acceptable)
        format ? process_mertics_request(format) : not_acceptable(FORMATS)
      else
        @app.call(env)
      end
    end

    def process_mertics_request(format)
      collect_metrics
      respond_with(format)
    end

    def collect_metrics
      @dj_total_count.set(Delayed::Job.count)
      @dj_total_pending_count.set(
        Delayed::Job.where(attempts: 0, locked_at: nil).count
      )

      Delayed::Job.group(:queue, :priority, :attempts)
                  .count.each do |data, count|
        @dj_count.set(count, labels: {
                        queue: data[0],
                        priority: data[1],
                        attempts: data[2]
                      })
        next unless (data[2]).zero?

        @dj_pending_count.set(count, labels: {
                                queue: data[0],
                                priority: data[1]
                              })
      end

      Delayed::Job.where.not(last_error: nil)
                  .where(failed_at: nil).group(
                    :queue,
                    :priority,
                    :attempts
                  ).count.each do |data, count|
        @dj_error_count.set(count, labels: {
                              queue: data[0],
                              priority: data[1],
                              attempts: data[2]
                            })
      end

      Delayed::Job.where.not(failed_at: nil)
                  .group(:queue,
                         :priority).count.each do |data, count|
        @dj_failed_count.set(count, labels: {
                               queue: data.first,
                               priority: data.last
                             })
      end

      Delayed::Job.where(failed_at: nil)
                  .where('DATE(run_at) = DATE(?)', Time.now)
                  .group(:queue, :priority, :attempts).count
                  .each do |data, count|
        @dj_to_be_executed_today_count.set(count, labels: {
                                             queue: data[0],
                                             priority: data[1],
                                             attempts: data[2]
                                           })
      end

      Delayed::Job.where.not(failed_at: nil)
                  .where('DATE(run_at) = DATE(?)', Time.now)
                  .group(:queue, :priority, :attempts).count
                  .each do |data, count|
        @dj_failed_today_count.set(count, labels: {
                                     queue: data[0],
                                     priority: data[1],
                                     attempts: data[2]
                                   })
      end

      jobs_handler('failed_at is NULL').each do |data, count|
        @dj_handler_count.set(count, labels: {
                                queue: data[0],
                                priority: data[1],
                                attempts: data[2],
                                handler: data[3]
                              })
      end

      jobs_handler('last_error is not NULL').each do |data, count|
        @dj_handler_error_count.set(count, labels: {
                                      queue: data[0],
                                      priority: data[1],
                                      attempts: data[2],
                                      handler: data[3]
                                    })
      end

      jobs_methods(false).each do |data, count|
        @dj_performable_count.set(count, labels: {
                                    queue: data[0],
                                    priority: data[1],
                                    attempts: data[2],
                                    handler: data[3],
                                    object: data[4],
                                    method_name: data[5]
                                  })
      end

      jobs_methods(true).each do |data, count|
        @dj_performable_failed_count.set(count, labels: {
                                           queue: data[0],
                                           priority: data[1],
                                           attempts: data[2],
                                           handler: data[3],
                                           object: data[4],
                                           method_name: data[5]
                                         })
      end
    end

    def jobs_handler(condition)
      Delayed::Job.where(condition.to_s)
                  .each_with_object(Hash.new(0)) do |dj, counts|
        handler = dj.handler.to_s.match(
          %r{!ruby/object:([^\n]+)}
        ).to_a[1].to_s.gsub(/ {}/, '')
        key = [dj.queue, dj.priority, dj.attempts, handler]
        counts[key] += 1
      end
    end

    def jobs_methods(failed = false)
      not_val = 'not ' if failed
      Delayed::Job.where("failed_at is #{not_val}NULL")
                  .where("handler like '%Delayed::Performable%'")
                  .reduce(Hash.new(0)) do |counts, dj|
        process(dj, counts)
      end
    end

    def process(job, counts)
      handler_str = job.handler.to_s
      handler = handler_str.match(
        %r{!ruby/object:([^\n]+)}
      ).to_a[1].to_s.gsub(/ {}/, '')
      object = handler_str.match(
        %r{(serialized_)?object: !ruby/(class '|object:)([^(\n|')]+)}
      ).to_a[3]
      method_name = handler_str.match(/method_name: ([^\n]+)/).to_a[1]

      key = [job.queue, job.priority, job.attempts,
             handler, object, method_name]

      counts[key] += 1
      counts
    end

    def init_delayed_jobs_metrics
      @dj_total_count = @registry.gauge(
        :delayed_jobs_total_count,
        docstring: 'The Delayed Jobs total count.'
      )

      @dj_total_pending_count = @registry.gauge(
        :delayed_jobs_pending_total_count,
        docstring: 'The Pending Delayed Jobs total '\
                   'count (Jobs with 0 attempts).'
      )

      @dj_count = @registry.gauge(
        :delayed_jobs_queue_total_count,
        docstring: 'The Delayed Jobs total count Per Queue.',
        labels: %i[queue priority attempts]
      )

      @dj_pending_count = @registry.gauge(
        :delayed_jobs_queue_pending_total_count,
        docstring: 'The Pending Delayed Jobs total count Per Queue.',
        labels: %i[queue priority]
      )

      @dj_error_count = @registry.gauge(
        :delayed_jobs_queue_error_total_count,
        docstring: 'The total count of delayed jobs with '\
                   'errors (Terminated Jobs do not count).',
        labels: %i[queue priority attempts]
      )

      @dj_failed_count = @registry.gauge(
        :delayed_jobs_queue_failed_total_count,
        docstring: 'The total count of the failed delayed '\
                   'jobs with errors (Jobs will not be retryed anymore).',
        labels: %i[queue priority]
      )

      @dj_to_be_executed_today_count = @registry.gauge(
        :delayed_jobs_to_be_executed_today_count,
        docstring: 'The total count of the delayed jobs '\
                   'that should be executed today).',
        labels: %i[queue priority attempts]
      )

      @dj_failed_today_count = @registry.gauge(
        :delayed_jobs_faild_today_count,
        docstring: 'The total count of the delayed jobs that faild today).',
        labels: %i[queue priority attempts]
      )

      @dj_handler_count = @registry.gauge(
        :delayed_jobs_handler_count,
        docstring: 'The total count of the active delayed '\
                   'jobs per handler class).',
        labels: %i[queue priority attempts handler]
      )

      @dj_handler_error_count = @registry.gauge(
        :delayed_jobs_handler_error_count,
        docstring: 'The total count of the delayed jobs '\
                   'with errors per handler class).',
        labels: %i[queue priority attempts handler]
      )

      @dj_performable_count = @registry.gauge(
        :delayed_jobs_performable_count,
        docstring: 'The total count of the delayed jobs '\
                   'for the performmable actions).',
        labels: %i[queue priority attempts handler object method_name]
      )

      @dj_performable_failed_count = @registry.gauge(
        :delayed_jobs_performable_failed_count,
        docstring: 'The total count of the delayed jobs '\
                   'for the performmable actions).',
        labels: %i[queue priority attempts handler object method_name]
      )
    end
  end
end
# rubocop:enable Metrics/MethodLength, Metrics/ClassLength, Metrics/AbcSize
