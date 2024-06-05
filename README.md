# Ml::Service::Isolation

Service for isolation operations on forest (outlier isolation, novelty isolation).

## Installation

First get ruby (e.g. [rbenv](https://github.com/rbenv/rbenv)) and [bundler](https://bundler.io/docs.html)

(Optional) Create your gem

    $ bundle gem mygem

Add dependency for the forest

    $ bundle add ml-forest --github=forest-implementation/ml-forest

Add dependency for this service

    $ bundle add ml-service-isolation --github=forest-implementation/ml-service-isolation


## Usage

#### Novelty

In your file, import forest and the desired service

```Ruby
require "ml/forest"
require "ml/service/isolation/novelty"

forest = Ml::Forest::Tree.new([5, 8, 3, 4, 2, 7].map{|x| [x]} , trees_count: 1, forest_helper: Ml::Service::Isolation::Novelty.new(ranges: [0..10]))

pp forest.evaluate_forest([6])
pp forest.evaluate_forest([6.24])
```

or with anomaly scores

```Ruby
# learning input
input = [[5], [8], [3], [4], [2], [7]]
forest = Ml::Forest::Tree.new(input, trees_count: 5, forest_helper: Ml::Service::Isolation::Novelty.new)

# evaluate forest depths for one point
depths_first = forest.evaluate_forest([5]).map(&:depth)
Evaluatable.evaluate_anomaly_score_s(depths_first, input.size) # 0.23 (<0.5 => not a novelty)


depths_second = forest.evaluate_forest([3000]).map(&:depth)
Evaluatable.evaluate_anomaly_score_s(depths_second, input.size) # 0.81 (>0.5 => definitely novel)

```

#### Outlier

```Ruby
require_relative "ruby/version"
require "ml/forest"
require "ml/service/isolation/outlier"

forest = Ml::Forest::Tree.new([5, 8, 3, 4, 2, 7].map{|x| [x]} , trees_count: 1, forest_helper: Ml::Service::Isolation::Outlier.new)

pp forest.evaluate_forest([6])
pp forest.evaluate_forest([1])
pp forest.fit_predict([55])
```

## Test

    $ bundle exec rake test


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/ml-service-novelty.
