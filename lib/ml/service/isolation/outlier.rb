# frozen_string_literal: true

require_relative "novelty/version"

module Ml
  module Service
    module Isolation
      class Outlier
        def self.ahoj
          p "jsem outlier"
        end
      end
    end
  end
end
