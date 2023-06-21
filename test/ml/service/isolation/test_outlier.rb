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

    forest = Ml::Forest::Tree.new(input, trees_count: 4, forest_helper: Ml::Service::Isolation::Outlier.new)

    anomaly = forest.evaluate_forest([2, 2])
    a_depths = anomaly.map(&:depth)

    regular = forest.evaluate_forest([1, 1])
    r_depths = regular.map(&:depth)

    assert_operator Evaluatable.evaluate_anomaly_score_s(a_depths, input.size), :>, 0.6
    assert_operator Evaluatable.evaluate_anomaly_score_s(r_depths, input.size), :<, 0.5
  end

  def test_anomaly_score_zero_to_one
    input = [[0.51], [0.9], [0.48], [0.45]]

    forest = Ml::Forest::Tree.new(input, trees_count: 4, forest_helper: Ml::Service::Isolation::Outlier.new)

    anomaly = forest.evaluate_forest([0.89])
    a_depths = anomaly.map(&:depth)
    p a_depths

    regular = forest.evaluate_forest([0.47])
    r_depths = regular.map(&:depth)
    p r_depths

    assert_operator Evaluatable.evaluate_anomaly_score_s(a_depths, input.size), :>, 0.6
    assert_operator Evaluatable.evaluate_anomaly_score_s(r_depths, input.size), :<, 0.5
  end

end
