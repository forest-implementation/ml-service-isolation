# frozen_string_literal: true

require "bundler"
Bundler.require(:test)

require "test_helper"
require "ml/service/isolation/noutlier"

require "ml/forest"

class Ml::Service::Isolation::TestNoutlier < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Ml::Service::Isolation::VERSION
  end

  def test_min_max
    data = [[1, 5], [3, 4], [0, 20]]
    res = Ml::Service::Isolation::Noutlier.min_max(data)
    assert_equal res, [0..3, 4..20]
  end

  def test_pregroup
    data = [[1, 5], [3, 4], [3, 17], [4, 19], [0, 20]]
    split_point = 15
    dimension = 1
    res = Ml::Service::Isolation::Noutlier.new.pregroup(data, split_point, dimension)
    assert_equal res, [[1..3, 4..5], [0..4, 17..20]]
  end

  def test_decision_function
    ranges =[[0.0..3000, 0.0..50],[0.0..3000, 50.0..100]]
    data = [[1, 5], [3, 4], [3, 17], [4, 19], [0, 20]]
    split_point = Ml::Service::Isolation::Noutlier::SplitPointD.new(70, 1,ranges ,ranges, data)
    element = [5.0, 75.0]
    res1 = Ml::Service::Isolation::Noutlier.new.decision_function(split_point).call(element)
    
    assert_equal res1, [0.0..3000, 50.0..100]

    element2 = [2.0, 25.0]
    res2 = Ml::Service::Isolation::Noutlier.new.decision_function(split_point).call(element2)
    
    assert_equal res2, [0.0..3000, 0.0..50]
  end
end
