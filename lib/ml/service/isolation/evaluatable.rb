module Evaluatable
  def self.harmonic_number(num)
    Math.log(num) + 0.5772156649
  end

  def self.harmonic_number_exact(num)
    (1...num).map { |x| 1.0 / x }.sum
  end

  def self.evaluate_path_length_c(batch_size)
    return 1 if batch_size == 2
    return 0 if batch_size < 2

    2 * harmonic_number(batch_size - 1) - 2 * (batch_size - 1) / batch_size
  end

  # E(h(x)) is the average of h(x) from a collection of iTrees
  def self.evaluate_average_e(depths)
    depths.sum(0.0) / depths.length
  end

  # depths are the depths returned by evalute_forest
  def self.evaluate_anomaly_score_s(depths, batch_size)
    2 ** -(evaluate_average_e(depths) / evaluate_path_length_c(batch_size))
  end
end

