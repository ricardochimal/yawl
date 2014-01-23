require "queue_classic"

module Yawl
  class Worker < QC::Worker
    def self.start
      worker = new

      trap("TERM") do
        worker.stop
        raise SignalException.new("SIGTERM")
      end

      worker.start
    end
  end
end
