require "sequel"

module Yawl
  class StepAttempt < Sequel::Model
    many_to_one :step

    def output
      (super || "")
    end
  end
end
