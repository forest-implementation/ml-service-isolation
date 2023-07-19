# frozen_string_literal: true
require "bundler"
Bundler.require(:test)

require "test_helper"
require "ml/service/isolation/outlier"

require 'ml/forest'

class Ml::Service::Isolation::TestOutlier < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Ml::Service::Isolation::VERSION
  end

  def test_anomaly_score
    input = [[1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [2, 2]]
    #size = input.size
    #p size
    service = Ml::Service::Isolation::Outlier.new(batch_size: 5)
    forest =  Ml::Forest::Tree.new(input, trees_count: 4, forest_helper: service)

    #anomaly = forest.evaluate_forest([2, 2])

    #regular = forest.evaluate_forest([1, 1])

    #assert_operator service.evaluate_score(anomaly), :>, 0.6
    #assert_operator service.evaluate_score(regular), :<, 0.5
  end

  def test_anomaly_score_zero_to_one
    # TODO: občas padá
    input = [[0.51], [0.9], [0.48], [0.45]]

    service = Ml::Service::Isolation::Outlier.new(batch_size: 4)
    forest = Ml::Forest::Tree.new(input, trees_count: 4, forest_helper: service)

    anomaly = forest.evaluate_forest([0.89])

    regular = forest.evaluate_forest([0.47])
    
    ans = service.evaluate_score(anomaly)
    res = service.evaluate_score(regular)
    assert_operator ans.score, :>, 0.6
    assert_operator res.score, :<, 0.5
  end

end
