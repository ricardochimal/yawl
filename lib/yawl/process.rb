require "sequel"
require "securerandom"

require "yawl/log"

module Yawl
  class Process < Sequel::Model
    plugin :validation_helpers
    one_to_many :steps, :order => [:seq]

    class ConcurrencyError < RuntimeError; end
    class RequestIdAttributeMismatch < RuntimeError; end

    def self.log(data, &block)
      Log.log({ ns: "yawl-process" }.merge(data), &block)
    end

    def log(data, &block)
      self.class.log({ process_id: id, desired_state: desired_state }.merge(data), &block)
    end

    def self.existing_by_request_id_and_attributes(request_id, attributes)
      return nil unless request_id
    end

    def self.web_only_attributes
      %w[config desired_state request_id]
    end

    def self.clean_attributes(attributes)
      attributes.reject {|k, v| !web_only_attributes.include?(k.to_s) }
    end

    def before_validation
      super
      if new?
        self.name = SecureRandom.uuid
        self.created_at = Time.now
      end
    end

    def validate
      super
      validates_presence :name
      validates_includes ProcessDefinitions.all_names, :desired_state
    end

    def start
      realize_process_definition
      start_first_unfinished_step_or_complete
    end

    def running?
      !%w[completed failed].include?(state)
    end

    def object
      return unless values[:object_id] && object_type

      klass = Object.const_get(object_type)
      klass[ values[:object_id] ]
    end

    def current?
      self.id == self.class.filter(:object_type => object_type, :object_id => values[:object_id]).order(:id).reverse.get(:id)
    end

    def start_first_unfinished_step_or_complete
      unless start_first_unfinished_step
        log(at: "completed")
        update(:state => "completed")
        end_state_reached
      end
    end

    def start_first_unfinished_step
      if unfinished_step = unfinished_steps.first
        update(:state => "executing")
        unfinished_step.start
        unfinished_step
      end
    end

    def step_finished
      start_first_unfinished_step_or_complete
    end

    def step_failed
      log(at: "failed")
      update(:state => "failed")
      end_state_reached
    end

    def next_step_seq
      steps_dataset.count == 0 ? 1 : steps_dataset.last.seq + 1
    end

    def add_step(data = {})
      data[:seq] ||= next_step_seq
      super(data)
    end

    def unfinished_steps
      steps_dataset.where("state != 'completed'")
    end

    def end_state_reached
    end

    def callback_payload
      {
        "process" => to_public_h.merge("url" => Urls.process(self))
      }
    end

    def merged_config
      default_config.deep_merge(config || {})
    end

    def default_config
      {
        "ion_branch" => "master",
        "manifesto_source_manifest" => "production",
        "manifesto_releases" => {}
      }
    end

    def realize_process_definition
      log(fn: "realize_process_definition") do
        ProcessDefinitions.realize_on(desired_state, self)
        save # if realizing made any changes, such as to config
      end
    end

    def to_public_h
      {
        "name" => name,
        "desired_state" => desired_state,
        "state" => state,
        "config" => merged_config
      }
    end
  end
end
