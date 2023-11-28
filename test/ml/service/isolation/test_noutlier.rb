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

  def test_split_ranges
    data = [[1, 5], [3, 4], [3, 17], [4, 19], [0, 20]]
    split_point = 15
    dimension = 1
    res = Ml::Service::Isolation::Noutlier.new.split_ranges(data, split_point, dimension)
    assert_equal res, [[1..3, 4..5], [0..4, 17..20]]
  end
end
