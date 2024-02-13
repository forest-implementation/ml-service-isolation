# frozen_string_literal: true

require_relative "novelty"

module Ml::Service::Isolation
  class Noutlier < Novelty
    def self.min_max(data, max_dimension = 1)
      return [Float::INFINITY..-Float::INFINITY] * max_dimension if data.empty?
      pp data
      dimensions = data[0].length
      (0...dimensions).map do |dim|
        min, max = data.transpose[dim].minmax
        min..max
      end
    end

    # def get_sample(data, _ = 0)
    #   sample = data.sample(@batch_size, random: @random)
    #   @batch_size = sample.size if @batch_size > sample.size
    #   sample.size != @batch_size and pp "sample != batch_size"
    #   #new_ranges = self.class.min_max(sample)
    #   pp "assignuju old range"
    #   pp @ranges
    #   DataPoint.new(depth: 0, data: sample, ranges: @ranges, old_range: @ranges)
    # end

    def decision_function(split_point)
      lambda { |x|
        ranges = split_point.ranges
        pp ranges
        range = ranges.transpose[split_point.dimension]
        if (range[split_point.dimension].end < split_point.split_point) == (x[split_point.dimension] < split_point.split_point)
          res = ranges[split_point.dimension]
        else
          res = ranges[1 - split_point.dimension]
        end
        return res
      }
    end

    def split_ranges(data, split_point, dimension, max_dimension)
      g = { true => [], false => [] }.merge(data.group_by { |x| x[dimension] <= split_point })
      pp split_point
      pp g.values
      g.values.map { |v| self.class.min_max(v, max_dimension) }
    end

    def split_point(data_point)
      dimension = data_point.data[0].length
      random_dimension = @random.rand(0...dimension)
      range_dimension = data_point.ranges[random_dimension]
      pp range_dimension
      split_point = @random.rand(range_dimension)
      ranges = split_ranges(data_point.data, split_point, random_dimension, dimension)
      SplitPointD.new(split_point, random_dimension, ranges, data_point.ranges, data_point.data)
    end
  end
end
