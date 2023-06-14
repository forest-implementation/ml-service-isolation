# frozen_string_literal: true

require_relative "version"
require_relative "evaluatable"

module Ml
  module Service
    module Isolation
      class Outlier
        include Evaluatable

        SplitPointD = Data.define(:split_point, :dimension)
        DataPoint = Data.define(:depth, :data)

        def initialize(batch_size: 128, max_depth: Math.log(batch_size, 2), random: Random.new)
          @batch_size = batch_size
          @max_depth = max_depth
          @random = random
        end

        def get_sample(data, _)
          DataPoint.new(depth: 0, data: data.sample(@batch_size, random: @random))
        end

        def split_point(data_point)
          dimension = data_point.data[0].length
          random_dimension = rand(0...dimension)
          min, max = data_point.data.flat_map { |x| x[random_dimension] }.minmax
          SplitPointD.new(rand(min.to_f..max.to_f), random_dimension)
        end

        def decision_function(split_point_d)
          ->(x) { x[split_point_d.dimension] < split_point_d.split_point }
        end

        def decision(element, split_point_d)
          decision_function(split_point_d).call(element)
        end

        def group(data_point, split_point_d)
          s = { true => [], false => [] }.merge(data_point.data.group_by(&decision_function(split_point_d)))
          s.transform_values do |group|
            DataPoint.new(depth: data_point.depth + 1, data: group)
          end
        end

        def end_condition(data_point)
          data_point.depth == @max_depth || data_point.data.length <= 1
        end
      end
    end
  end
end
