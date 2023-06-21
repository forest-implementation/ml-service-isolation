# frozen_string_literal: true
require "bundler"
Bundler.require(:test)

require "test_helper"
require "ml/service/isolation/novelty"

require 'ml/forest'
class Ml::Service::Isolation::TestNovelty < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Ml::Service::Isolation::VERSION
  end

  def test_split_point_ranges
    datapoint = Ml::Service::Isolation::Novelty.new(batch_size: 128, random: Random.new(2), range: (0..3000)).get_sample([[1, 1], [1, 1]], range: (0..3000))
    assert_equal datapoint.ranges, [0..3000, 0..3000]
  end

  def test_group
    ns = Ml::Service::Isolation::Novelty.new(batch_size: 128, random: Random.new(2), range: (0.0..3000))
    datapoint = ns.get_sample([[1, 1], [1, 1]])
    split_point = Ml::Service::Isolation::Novelty::SplitPointD.new(100, 1)
    groups = ns.group(datapoint, split_point)

    assert_equal groups[true].ranges, [0.0..3000, 0.0..100]
    assert_equal groups[false].ranges, [0.0..3000, 100..3000]

    split_point2 = Ml::Service::Isolation::Novelty::SplitPointD.new(200, 0)
    groups2 = ns.group(groups[true], split_point2)
    assert_equal groups2[true].ranges, [0..200, 0.0..100]
    assert_equal groups2[false].ranges, [200..3000, 0..100]
  end

  def test_novelty_run
    input = [[1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [2, 2]]

    forest = Ml::Forest::Tree.new(input, trees_count: 4, forest_helper: Ml::Service::Isolation::Novelty.new(range: (0..3000)))

    anomaly = forest.evaluate_forest([2, 2])
    a_depths = anomaly.map(&:depth)

    regular = forest.evaluate_forest([1, 1])
    r_depths = regular.map(&:depth)

    novelty = forest.evaluate_forest([2999, 2999])
    n_depths = novelty.map(&:depth)

    assert_operator Evaluatable.evaluate_anomaly_score_s(r_depths, input.size), :<, 0.5
    assert_operator Evaluatable.evaluate_anomaly_score_s(a_depths, input.size), :<, 0.5
    assert_operator Evaluatable.evaluate_anomaly_score_s(n_depths, input.size), :>, 0.6
  end

  def test_split_point_generator
    ns = Ml::Service::Isolation::Novelty.new(batch_size: 128, random: Random.new(2))

    dp = ns.get_sample([[1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [2, 2]])

    sd = ns.split_point(dp)
    assert_instance_of Float, sd.split_point
  end

end
