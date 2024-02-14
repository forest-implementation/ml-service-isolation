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

  def column_minmax(input, index)
    min, max = input.map { |x| x[index] }.minmax
    (min..max)
  end

  def test_end_condition
    dp = Ml::Service::Isolation::Outlier::DataPoint.new(depth: 50, data: [[1,2,3]])
    service = Ml::Service::Isolation::Outlier.new(batch_size: 5, max_depth: 10)
    assert service.end_condition(dp) == true
  end

  def test_split_point_ranges
    datapoint = Ml::Service::Isolation::Novelty.new(batch_size: 128, random: Random.new(2), ranges: [(0..3000), (0..3000)]).get_sample([[1, 1], [1, 1]])
    assert_equal datapoint.ranges, [0..3000, 0..3000]
  end

  def test_split_ranges
    ranges = [(0..100), (0..3000)]
    ns = Ml::Service::Isolation::Novelty.new(batch_size: 128, random: Random.new(2), ranges: ranges)
    first, second = ns.split_ranges(ranges, 1, 50)
    assert_equal first, [(0..100), (0..50)]
    assert_equal second, [(0..100), (50..3000)]
  end

  def test_group_middle_point
    ranges = [(0.0..100),]
    ns = Ml::Service::Isolation::Novelty.new(batch_size: 128, random: Random.new(2), ranges: ranges)
    data = [[1],[2],[3],[4],[5],[6],[7],[8],[9]]
    sp = Ml::Service::Isolation::Novelty::SplitPointD.new(5, 0, ns.split_ranges(ranges, 0, 5.0), ranges, data)
    groups = ns.group(Ml::Service::Isolation::Novelty::DataPoint.new(0, data, ranges, ranges), sp)
    assert_equal [[1,2,3,4]].transpose, groups[[0.0..5.0]].data
    assert_equal [[5,6,7,8,9]].transpose, groups[[5.0..100]].data
  end

  def test_group
    old_ranges = [(0.0..3000), (0.0..100)]
    ns = Ml::Service::Isolation::Novelty.new(batch_size: 128, random: Random.new(2), ranges: old_ranges)
    datapoint = ns.get_sample([[1, 1], [1, 1]])
    split_point = Ml::Service::Isolation::Novelty::SplitPointD.new(50, 1, [[0.0..3000, 0.0..50],[0.0..3000, 50.0..100]], old_ranges, datapoint.data)
    groups = ns.group(datapoint, split_point)

    assert_equal groups[[0.0..3000, 0.0..50]].ranges, [0.0..3000, 0.0..50]
    assert_equal groups[[0.0..3000, 50.0..100]].ranges, [0.0..3000, 50.0..100]

    split_point2 = Ml::Service::Isolation::Novelty::SplitPointD.new(200, 0, [ [0..200, 0.0..50], [200..3000, 0.0..50] ], old_ranges, datapoint.data)
    groups2 = ns.group(datapoint, split_point2)
    assert_equal groups2[[0..200, 0.0..50]].ranges, [0..200, 0.0..50]
    assert_equal groups2[[200..3000, 0.0..50]].ranges, [200..3000, 0.0..50]
  end

  def test_novelty_run_no_trivial
    #TODO: in-progress
    input = [[1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [2, 2]]
    service = Ml::Service::Isolation::Novelty.new(ranges: [(0.0..10.0), (0.0..10.0)])
    forest = Ml::Forest::Tree.new(input, trees_count: 4, forest_helper: service)

    regular = forest.evaluate_forest([1, 1])

    # TODO: FAILUJE
    anomaly = forest.evaluate_forest([1.999, 1.999])

    novelty = forest.evaluate_forest([10, 10])

    assert_operator service.evaluate_score(regular).score, :<, 0.6
    assert_operator service.evaluate_score(anomaly).score, :<, 0.6
    assert_operator service.evaluate_score(novelty).score, :>, 0.6
  end

  def test_novelty_run
    input = [[1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [2, 2]]

    forest = Ml::Forest::Tree.new(input, trees_count: 4, forest_helper: Ml::Service::Isolation::Novelty.new(ranges: [(0..3000), (0..3000)]))

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
    ns = Ml::Service::Isolation::Novelty.new(batch_size: 128, random: Random.new(2), ranges: [(0.0..10),(1.0..10)])

    dp = ns.get_sample([[1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [2, 2]])

    sd = ns.split_point(dp)
    # 11 (ranges.size) / 2
    assert_equal 5.5, sd.split_point
  end

  def test_split_point_decimal
    ns = Ml::Service::Isolation::Novelty.new(batch_size: 128, random: Random.new(2), ranges: [(0.0..10),(2.3..2.7)])

    dp = ns.get_sample([[1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [2, 2]])

    sd = ns.split_point(dp)
    # 5 (ranges.size) / 2 = 2.5
    assert_equal 2.5, sd.split_point
  end

end
