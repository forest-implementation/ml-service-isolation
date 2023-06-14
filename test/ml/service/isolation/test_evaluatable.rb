# frozen_string_literal: true
require "bundler"
Bundler.require(:test)

require "test_helper"
require "ml/service/isolation/evaluatable"
class Ml::Service::Isolation::TestNovelty < Minitest::Test
  include Evaluatable

  def test_isolation_anomaly_score_s
    # if sample size -1 == average, then 0
    # [1,2,3] are depths of 3 trees
    res0 = Evaluatable.evaluate_anomaly_score_s([9999], 10000)
    assert_in_delta res0, 0

    res1 = Evaluatable.evaluate_anomaly_score_s([-1, 0, 1], 3)
    assert_equal res1, 1

    res05 = Evaluatable.evaluate_anomaly_score_s([Evaluatable.evaluate_path_length_c(100)], 100)
    assert_equal res05, 0.5
  end

  def test_path_length_c
    res4 = Evaluatable.evaluate_path_length_c(4)
    assert_operator 2, :<, res4

    res7 = Evaluatable.evaluate_path_length_c(7)
    assert_operator 3, :<, res7

    res0 = Evaluatable.evaluate_path_length_c(0)
    assert_equal res0, 0

    res2 = Evaluatable.evaluate_path_length_c(2)
    assert_equal res2, 1

    res1 = Evaluatable.evaluate_path_length_c(1)
    assert_equal res1, 0
  end

end
