# frozen_string_literal: true

require "bundler"
Bundler.require(:test)

require "test_helper"
require "ml/service/isolation/outlier"

require "ml/forest"

class Ml::Service::Isolation::TestOutlier < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Ml::Service::Isolation::VERSION
  end

  def test_end_condition
    dp = Ml::Service::Isolation::Outlier::DataPoint.new(depth: 50, data: [[1, 2, 3]])
    service = Ml::Service::Isolation::Outlier.new(batch_size: 5, max_depth: 10)
    assert service.end_condition(dp) == true
  end

  def test_anomaly_score_new
    input = [[1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1],
             [1, 1], [2, 2]]

    service = Ml::Service::Isolation::Outlier.new(batch_size: 12)
    forest =  Ml::Forest::Tree.new(input, trees_count: 4, forest_helper: service)

    anomaly = forest.evaluate_forest([2, 2])

    regular = forest.evaluate_forest([1, 1])

    assert_operator service.evaluate_score(anomaly).score, :>, 0.6
    assert_operator service.evaluate_score(regular).score, :<, 0.6
  end

  def test_anomaly_score_new2
    input = [[1, 2], [3, 4], [5, 6], [7, 8]]

    service = Ml::Service::Isolation::Outlier.new(batch_size: 2)
    forest =  Ml::Forest::Tree.new(input, trees_count: 4, forest_helper: service)

    anomaly = forest.evaluate_forest([2, 2])

    regular = forest.evaluate_forest([1, 1])

    assert_operator service.evaluate_score(anomaly).score, :>, 0.6
    assert_operator service.evaluate_score(regular).score, :<, 0.6
  end

  def test_anomaly_score_zero_to_one
    # TODO: občas padá
    input = [[0.51], [0.52], [0.9], [0.48], [0.45], [0.41], [0.4], [0.46], [0.95]]

    service = Ml::Service::Isolation::Outlier.new(batch_size: 5)
    forest = Ml::Forest::Tree.new(input, trees_count: 10, forest_helper: service)

    anomaly = forest.evaluate_forest([0.89])

    regular = forest.evaluate_forest([0.47])

    ans = service.evaluate_score(anomaly)
    res = service.evaluate_score(regular)
    assert_operator ans.score, :>, 0.6
    assert_operator res.score, :<, 0.6
  end

  def test_dimensional_min_max
    data = [[1, 2], [3, 4], [5, 6], [7, 8]]
    dp = Data.define(:data).new(data)
    assert_equal [1, 7], Ml::Service::Isolation::Outlier.min_max(dp, 0)
    assert_equal [[1, 7], [2, 8]], Ml::Service::Isolation::Outlier.dimensionial_min_max(dp, 0..1)
  end

  def test_dimensional_min_max2
    data = [[0, 1, 2, 3, 4, 5], [2, 1, 2, 1, 4, 2]].transpose
    dp = Data.define(:data).new(data)
    assert_equal [0, 5], Ml::Service::Isolation::Outlier.min_max(dp, 0)
    assert_equal [[0, 5], [1, 4]], Ml::Service::Isolation::Outlier.dimensionial_min_max(dp, 0..1)
  end

  def test_new_ranges
    data = [[1, 2], [3, 4], [5, 6], [7, 8]]
    data2 = [[5, -50], [1, 48], [4, 5], [12, 10]]
    dp = Data.define(:data).new(data)
    dp2 = Data.define(:data).new(data2)
    datapoints = [dp, dp2]

    assert_equal [[[1, 7], [2, 8]], [[1, 12], [-50, 48]]], Ml::Service::Isolation::Outlier.new_ranges(datapoints, 0..1)
  end

  def test_new_ranges2
    data = [[1, 1, 1, 1]]
    dp = Data.define(:data).new(data)
    datapoints = [dp, dp]

    assert_equal [[[1, 1]], [[1, 1]]], Ml::Service::Isolation::Outlier.new_ranges(datapoints, 0..0)
  end

  def test_equi_group_by
    data = [[1, 0], [1, 1], [2, 1], [1, 2]]
    sp = 1
    dimension = 1
    dp = Data.define(:data).new(data)

    s = { -1 => [[1, 0]], 0 => [[1, 1], [2, 1]], 1 => [[1, 2]] }
    assert_equal s, Ml::Service::Isolation::Outlier.equi_group_by(dp, sp, dimension)
  end

  def test_mid_to_l_r
    input = { -1 => [[1, 0]], 0 => [[1, 1], [2, 1]], 1 => [[1, 2]] }
    expected = { -1 => [[1, 0], [1, 1], [2, 1]], 1 => [[1, 2], [1, 1], [2, 1]] }
    assert_equal expected, Ml::Service::Isolation::Outlier.mid_to_l_r(input)
  end
end
