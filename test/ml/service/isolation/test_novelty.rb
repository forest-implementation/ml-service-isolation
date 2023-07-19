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

  def test_group
    ns = Ml::Service::Isolation::Novelty.new(batch_size: 128, random: Random.new(2), ranges: [(0.0..3000), (0.0..100)])
    datapoint = ns.get_sample([[1, 1], [1, 1]])
    split_point = Ml::Service::Isolation::Novelty::SplitPointD.new(50, 1)
    groups = ns.group(datapoint, split_point)

    assert_equal groups[true].ranges, [0.0..3000, 0.0..50]
    assert_equal groups[false].ranges, [0.0..3000, 50..100]

    split_point2 = Ml::Service::Isolation::Novelty::SplitPointD.new(200, 0)
    groups2 = ns.group(groups[true], split_point2)
    assert_equal groups2[true].ranges, [0..200, 0.0..50]
    assert_equal groups2[false].ranges, [200..3000, 0.0..50]
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

  def test_novelty_run_no_trivial
    #in-progress
    input = [[1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [2, 2]]
    service = Ml::Service::Isolation::Novelty.new(ranges: [(0.0..10.0), (0.0..10.0)])
    forest = Ml::Forest::Tree.new(input, trees_count: 4, forest_helper: service)

    regular = forest.evaluate_forest([1, 1])

    anomaly = forest.evaluate_forest([1.999, 1.999])

    novelty = forest.evaluate_forest([10, 10])

    assert_operator service.evaluate_score(regular).score, :<, 0.5
    #assert_operator service.evaluate_score(anomaly).score, :<, 0.5
    assert_operator service.evaluate_score(novelty).score, :>, 0.6
  end

  def test_novelty_run_from_csv
    file = File.readlines('test/ml/service/isolation/data.csv')
    data = file.drop_while { |v| !v.start_with? '@DATA' }[1..-1] .map { |line| line.chomp.split(',') }
    p input = data.take_while { |x| x[2] == "1" } .map { |x| x[0..1].map { |x| x.to_f } }
    p novelty = data.drop_while { |x| x[2] == "1" } .map { |x| x[0..1].map { |x| x.to_f } }
    service = Ml::Service::Isolation::Novelty.new(ranges: [(11.0..67.0), (0.0..33.0)])
    forest = Ml::Forest::Tree.new(input, trees_count: 24, forest_helper: service)

    novelty.map { |x| forest.evaluate_forest(x) } .each do |t|
      e = service.evaluate_score(t)
      assert_operator e.score, :>, 0.6
    end


    input.map { |x| forest.evaluate_forest(x) } .each do |x|
      e = service.evaluate_score(x)
      assert_operator e.score, :<, 0.5
    end

  end

  def test_split_point_generator
    ns = Ml::Service::Isolation::Novelty.new(batch_size: 128, random: Random.new(2), ranges: [(5.0...15.2),(5.0...15.2)])

    dp = ns.get_sample([[1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [2, 2]])

    sd = ns.split_point(dp)
    # 10 (ranges.size) / 2
    assert_equal 10.1, sd.split_point
  end

end
