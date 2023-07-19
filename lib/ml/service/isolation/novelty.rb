# frozen_string_literal: true

require_relative "version"
require_relative "evaluatable"

module Ml
  module Service
    module Isolation
      class Novelty
        include Evaluatable

        SplitPointD = Data.define(:split_point, :dimension)
        DataPoint = Data.define(:depth, :data, :ranges)
        Score = Data.define(:score, :novelty?, :depths)

        attr_reader :batch_size, :max_depth, :random, :ranges

        def initialize(batch_size: 128, max_depth: Math.log(batch_size, 2), random: Random.new, ranges: [(0.0..1)])
          @batch_size = batch_size
          @max_depth = max_depth
          @random = random
          @ranges = ranges
        end

        def get_sample(data, _ = 0)
          # ranges = (1..data[0].length).map { |_| @range }
          DataPoint.new(depth: 0, data: data.sample(@batch_size, random: @random), ranges: @ranges)
        end

        def split_point(data_point)
          dimension = data_point.data[0].length
          random_dimension = @random.rand(0...dimension)
          range_dimension = data_point.ranges[random_dimension]
          # TODO: TEST
          SplitPointD.new((range_dimension.min + range_dimension.max) / 2.0, random_dimension)
        end

        def decision_function(split_point_d)
          ->(x) { x[split_point_d.dimension] < split_point_d.split_point }
        end

        def decision(element, split_point_d)
          decision_function(split_point_d).call(element)
        end

        def split_ranges(ranges, dimension, split_point)
          new_rangers = ranges.clone
          new_rangers[dimension] = ranges[dimension].min..split_point

          new_rangers2 = ranges.clone
          new_rangers2[dimension] = split_point..ranges[dimension].max

          [new_rangers, new_rangers2]
        end

        def group(data_point, split_point_d)
          s = { true => [], false => [] }.merge(data_point.data.group_by(&decision_function(split_point_d)))

          new_ranges, new_ranges2 = split_ranges(data_point.ranges, split_point_d.dimension, split_point_d.split_point)

          {
            true => DataPoint.new(depth: data_point.depth + 1, data: s[true], ranges: new_ranges),
            false => DataPoint.new(depth: data_point.depth + 1, data: s[false], ranges: new_ranges2),
          }
        end

        def end_condition(data_point)
          data_point.depth == @max_depth || data_point.data.length <= 1
        end

        def evaluate_score(evaluated_data)
          depths = evaluated_data.map { |x| x.depth + Evaluatable.evaluate_path_length_c(x.data.size) }
          score = Evaluatable.evaluate_anomaly_score_s(depths, @batch_size)
          Score.new(score, score >= 0.6, Evaluatable.evaluate_average_e(depths))
        end

      end
    end
  end
end
