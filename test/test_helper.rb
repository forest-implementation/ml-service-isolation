# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "ml/service/isolation/novelty"
require "ml/service/isolation/outlier"
require "ml/service/isolation/noutlier"

require "minitest/autorun"
