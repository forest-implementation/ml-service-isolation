# frozen_string_literal: true

require "bundler"
Bundler.require(:test)

require "test_helper"
require "ml/service/isolation/novelty"

require "ml/forest"
class Ml::Service::Isolation::TestNovelty < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Ml::Service::Isolation::VERSION
  end

  def column_minmax(input, index)
    min, max = input.map { |x| x[index] }.minmax
    (min..max)
  end

  def test_split_point_ranges
    datapoint = Ml::Service::Isolation::Novelty.new(
      batch_size: 128, random: Random.new(2),
      ranges: [0..3000, 0..3000]
    ).get_sample([[1, 1], [1, 1]])

    assert_equal [0..3000, 0..3000], datapoint.ranges
  end

  def test_split_ranges
    ranges = [0..100, 0..3000]
    ns = Ml::Service::Isolation::Novelty.new(batch_size: 128, random: Random.new(2), ranges: ranges)
    first, second = ns.split_ranges(ranges, 1, 50)

    assert_equal [0..100, 0..50],    first
    assert_equal [0..100, 50..3000], second
  end

  def test_group
    ns = Ml::Service::Isolation::Novelty.new(batch_size: 128, random: Random.new(2), ranges: [0.0..3000, 0.0..100])
    datapoint = ns.get_sample([[1, 1], [1, 1]])

    split_point = Ml::Service::Isolation::Novelty::SplitPointD.new(50, 1)
    groups = ns.group(datapoint, split_point)
    assert_equal [0.0..3000, 0.0..50], groups[true].ranges
    assert_equal [0.0..3000, 50..100], groups[false].ranges

    split_point2 = Ml::Service::Isolation::Novelty::SplitPointD.new(200, 0)
    groups2 = ns.group(groups[true], split_point2)
    assert_equal [0..200, 0.0..50],    groups2[true].ranges
    assert_equal [200..3000, 0.0..50], groups2[false].ranges
  end

  def test_novelty_run
    input = [[1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1],
             [1, 1], [2, 2]]

    forest = Ml::Forest::Tree.new(
      input,
      trees_count: 4,
      forest_helper: Ml::Service::Isolation::Novelty.new(ranges: [0..3000, 0..3000])
    )

    regular = forest.evaluate_forest([1, 1]).map(&:depth)
    anomaly = forest.evaluate_forest([2, 2]).map(&:depth)
    novelty = forest.evaluate_forest([2999, 2999]).map(&:depth)

    assert_operator Evaluatable.evaluate_anomaly_score_s(regular, input.size), :<, 0.5
    assert_operator Evaluatable.evaluate_anomaly_score_s(anomaly, input.size), :<, 0.5
    assert_operator Evaluatable.evaluate_anomaly_score_s(novelty, input.size), :>, 0.6
  end

  def test_split_point_generator
    ns = Ml::Service::Isolation::Novelty.new(batch_size: 128, random: Random.new(2), ranges: [0.0..10, 1.0..10])

    dp = ns.get_sample([[1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1],
                        [1, 1], [1, 1], [2, 2]])

    sd = ns.split_point(dp)
    # 10 (ranges.size) / 2
    assert_equal 5, sd.split_point
  end
end
