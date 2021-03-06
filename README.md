# DelayedJobMetrics

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/delayed_job_metrics`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'delayed_job_metrics'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install delayed_job_metrics

## Usage

### Enable metrics middelware

```
  DELAYED_JOB_METRICS_ENABLED=true
```

### Start Rails server and start scraping metrics

```
 curl -fs http://127.0.0.1:3000/metrics
```


### Set metrics endpoint
Add the below envrinment variable to overwrite the default endpoint

```
  DELAYED_JOB_METRICS_ENNDPOINT=/my_endpoint
```

### Setup basic auth

```
 HTAUTH_METRICS_USER=user
 HTAUTH_METRICS_PASSWORD=secret
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/delayed_job_metrics. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/delayed_job_metrics/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the DelayedJobMetrics project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/delayed_job_metrics/blob/master/CODE_OF_CONDUCT.md).
