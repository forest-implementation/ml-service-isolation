# frozen_string_literal: true

require_relative "novelty"

module Ml::Service::Isolation
  class Noutlier < Novelty
    def self.min_max(data)
      dimensions = data[0].length
      (0...dimensions).map do |dim|
        min, max = data.transpose[dim].minmax
        min..max
      end
    end

    def decision_function(split_point)
      lambda { |x|
        pp x
        ranges = split_point.ranges
        range = ranges.transpose[split_point.dimension]
        if (range[split_point.dimension].max <= split_point.split_point) == (x[split_point.dimension] <= split_point.split_point)
          res = ranges[split_point.dimension]
        else
          res = ranges[1 - split_point.dimension]
        end
        return res
      }
    end

    def split_ranges(data, split_point, dimension)
      g = { -1 => [], 1 => [] }.merge(data.group_by { |x| x[dimension] <=> split_point })
      g.values.map { |v| self.class.min_max v }
    end

    def split_point(data_point)
      dimension = data_point.data[0].length
      random_dimension = @random.rand(0...dimension)
      range_dimension = data_point.ranges[random_dimension]
      split_point = @random.rand(range_dimension)
      ranges = split_ranges(data_point.data, split_point, random_dimension)
      SplitPointD.new(split_point, random_dimension, ranges, data_point.ranges)
    end
  end
end
