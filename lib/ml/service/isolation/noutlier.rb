# frozen_string_literal: true

require_relative "novelty"

module Ml::Service::Isolation
  class Noutlier < Novelty
    def self.min_max(data)
      dimensions = data[0].size
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

        range = ranges.transpose[split_point.dimension]

        branch = (range[0].end < split_point.split_point) == (x[split_point.dimension] <= split_point.split_point)
        ranges[branch ? 0 : 1]
      }
    end

    def pregroup(datapoint, split_point, dimension)
      g = { true => [], false => [] }.merge(datapoint.group_by { |x| x[dimension] < split_point })

      g.values.map { |v| self.class.min_max(v) }
    end

    def split_point(data_point)
      dimension = data_point.data[0].length
      # find dimension until there are distinct data in it
      random_dimension = (0...dimension).to_a.shuffle(random: @random).find {
         |dim| data_point.data.uniq { |x| x[dim] } .size > 1
      }
      range_dimension = data_point.ranges[random_dimension]
      split_point = @random.rand(range_dimension)
      ranges = pregroup(data_point.data, split_point, random_dimension)
      SplitPointD.new(split_point, random_dimension, ranges, data_point.ranges, data_point.data)
    end
  end
end
