# frozen_string_literal: true

require_relative "version"
require_relative "evaluatable"

module Ml
  module Service
    module Isolation
      class Outlier
        include Evaluatable

        SplitPointD = Data.define(:split_point, :ranges, :dimension)
        DataPoint = Data.define(:depth, :data)
        Score = Data.define(:score, :outlier?)

        attr_reader :batch_size, :max_depth, :random

        def initialize(batch_size: 128, max_depth: Math.log(batch_size, 2), random: Random.new)
          @batch_size = batch_size
          @max_depth = max_depth
          @random = random
        end

        def get_sample(data, _)
          sample = data.sample(@batch_size, random: @random)
          @batch_size = sample.size if @batch_size > sample.size
          pp "out: samplee != batch_size" + sample.size.to_s + "<" + batch_size.to_s if sample.size != @batch_size
          DataPoint.new(depth: 0, data: sample)
        end

        def self.min_max(data_point, dimension)
          data_point.data.transpose[dimension].minmax
        end

        def self.dimensionial_min_max(data_point, dimensions)
          dimensions.map { |dim| min_max(data_point, dim) }
        end

        def self.new_ranges(datapoints, dimensions)
          datapoints.map { |dp| dimensionial_min_max(dp, dimensions) }
        end

        def split_point(data_point)
          dimension = data_point.data[0].length
          random_dimension = rand(0...dimension)

          min, max = self.class.min_max(data_point, random_dimension)
          sp = rand(min.to_f..max.to_f)

          datapoints = { -1 => [], 0 => [], 1 => [] }.merge(data_point.data.group_by { |x| x[random_dimension] <=> sp })

          datapoints = datapoints.map do |key, value|
            key != 0 ? { key => value + datapoints[0] } : nil
          end.compact.reduce({}, :merge).values.map { |dato| DataPoint.new(0, dato) }

          new_ranges = self.class.new_ranges(datapoints, 0...dimension)

          SplitPointD.new(sp, new_ranges, random_dimension)
        end

        def self.decision_function(split_point)
          lambda { |x|
            # pp split_point
            range = split_point.ranges.transpose[split_point.dimension]
            # pp "range"
            # pp range
            # pp split_point.dimension
            # pp :r, range[split_point.dimension].max
            # pp :x, x[split_point.dimension]
            # pp :sp, split_point.split_point

            (range[split_point.dimension].max <= split_point.split_point) == (x[split_point.dimension] <= split_point.split_point) ? range[split_point.dimension] : range[1 - split_point.dimension]
          }
        end

        def decision(element, split_point_d)
          self.class.decision_function(split_point_d).call(element)
        end

        def group(data_point, split_point_d)
          s = { split_point_d.ranges[0] => [],
                split_point_d.ranges[1] => [] }.merge(data_point.data.group_by(&self.class.decision_function(split_point_d)))

          s.transform_values do |group|
            DataPoint.new(depth: data_point.depth + 1, data: group)
          end
        end

        def end_condition(data_point)
          data_point.depth >= @max_depth || data_point.data.length <= 1
        end

        def evaluate_score(evaluated_data)
          depths = evaluated_data.map { |x| x.depth + Evaluatable.evaluate_path_length_c(x.data.size) }
          score = Evaluatable.evaluate_anomaly_score_s(depths, @batch_size)
          Score.new(score, score >= 0.6)
        end
      end
    end
  end
end
