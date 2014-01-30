require "sequel"
require "queue_classic"
require "queue_classic-later"

require "yawl/log"

module Yawl
  class Step < Sequel::Model
    many_to_one :process
    one_to_many :attempts, :class => "Yawl::StepAttempt", :order => :started_at

    class Fatal < StandardError
      def initialize
        super("Fatal error in step")
      end
    end

    class Tired < StandardError
      def initialize
        super("Step slept")
      end
    end

    def self.log(data, &block)
      Log.log({ ns: "yawl-step" }.merge(data), &block)
    end

    def log(data, &block)
      self.class.log({ process_id: process.id, step_id: id, step_name: name }.merge(data), &block)
    end

    def self.execute(id)
      self[id].execute
    end

    def self.restart_interrupted
      where(:state => "interrupted").each do |step|
        step.start
      end
    end

    def duration
      if attempts.any?
        (attempts.last.completed_at || Time.now) - attempts.first.started_at
      end
    end

    def start
      log(fn: "start")
      update(:state => "pending")
      QC.enqueue("Yawl::Step.execute", id)
    end

    def start_in(seconds)
      log(fn: "start_in", seconds: seconds)
      QC.enqueue_in(seconds, "Yawl::Step.execute", id)
    end

    def start_after_delay
      start_in(real_step.delay_between_attempts)
    end

    def real_step
      @real_step ||= Steps.for(name, self)
    end

    def out_of_attempts?
      attempts.count >= real_step.attempts
    end

    def execute
      log(fn: "execute") do
        begin
          # TODO(dpiddy): transactions here?
          update(:state => "executing")
          attempt = add_attempt(:started_at => Time.now)
          real_step.run_with_log
          log(fn: "execute", at: "run_completed")
          attempt.update(:output => real_step.output, :completed_at => Time.now)
          update(:state => "completed")
          process.step_finished
        rescue Step::Fatal, Step::Tired, StandardError, SignalException => e
          log(:fn => "execute", :at => "caught_exception", :class => e.class, :message => e.message)
          attempt.update(:output => "#{real_step.output}\n\n---\nCAUGHT ERROR: #{e}\n#{e.backtrace.join("\n")}\n", :completed_at => Time.now)

          if out_of_attempts? || e.is_a?(Step::Fatal)
            update(:state => "failed")
            process.step_failed
            raise
          elsif SignalException === e && e.signm == "SIGTERM" # we are shutting down
            update(:state => "interrupted")
            raise
          else
            update(:state => "pending")
            start_after_delay
          end
        end
      end
    end

    def to_public_h
      {
        "seq" => seq,
        "name" => name,
        "state" => state
      }
    end
  end
end
