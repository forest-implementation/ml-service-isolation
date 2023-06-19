# Ml::Service::Novelty

TODO: Delete this and the text below, and describe your gem

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/ml/service/novelty`. To experiment with that code, run `bin/console` for an interactive prompt.

## Installation

TODO: Replace `UPDATE_WITH_YOUR_GEM_NAME_PRIOR_TO_RELEASE_TO_RUBYGEMS_ORG` with your gem name right after releasing it to RubyGems.org. Please do not do it earlier due to security reasons. Alternatively, replace this section with instructions to install your gem from git if you don't plan to release to RubyGems.org.

Install the gem and add to the application's Gemfile by executing:

    $ bundle add UPDATE_WITH_YOUR_GEM_NAME_PRIOR_TO_RELEASE_TO_RUBYGEMS_ORG

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install UPDATE_WITH_YOUR_GEM_NAME_PRIOR_TO_RELEASE_TO_RUBYGEMS_ORG

## Usage

### Novelty

For example of usage please refer to example project.

Simple usage on ml-forest could look like this

1. install ml-forest alongside with this service

Gemfile
```Ruby
gem "ml-forest"
gem "ml-service-isolation"
```

Usage
```ruby
# learning input
input = [[5], [8], [3], [4], [2], [7]]
forest = Ml::Forest::Tree.new(input, trees_count: 5, forest_helper: Ml::Service::Isolation::Novelty.new)

# evaluate forest depths for one point
depths_first = forest.evaluate_forest([5]).map(&:depth)
Evaluatable.evaluate_anomaly_score_s(depths_first, input.size) # 0.23 (<0.5 => not a novelty)


depths_second = forest.evaluate_forest([3000]).map(&:depth)
Evaluatable.evaluate_anomaly_score_s(depths_second, input.size) # 0.81 (>0.5 => definitely novel)

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/ml-service-novelty.
