require "stringio"
require "forwardable"

module Yawl
  module Steps
    class SetDefiner
      attr_reader :step_names

      def initialize(name, &block)
        @name = name
        @step_names = []
        @block = block
      end

      def run
        instance_eval(&@block)
      end

      def step(name, &block)
        Steps.step(name, &block).tap do |k|
          step_names.push(k.name)
        end
      end
    end

    def self.sets
      @sets ||= {}
    end

    def self.set(name, &block)
      name = name.to_sym
      definer = SetDefiner.new(name, &block)
      definer.run
      sets[name] = definer.step_names
    end

    def self.step(name, &block)
      name = name.to_sym
      Class.new(Base, &block).tap do |klass|
        klass.instance_eval "def name; #{name.inspect} end", __FILE__, __LINE__
        Base.register(klass)
      end
    end

    def self.realize_set_on(name, process)
      unless set_step_names = sets[name.to_sym]
        raise "Set #{name} not found"
      end

      set_step_names.each do |set_step_name|
        process.add_step(:name => set_step_name)
      end
    end

    def self.for(name, process_step)
      name = name.to_sym
      klass = Base.all_steps[name] || RealStepMissing
      klass.new(process_step)
    end

    class Base
      extend Forwardable

      def self.all_steps
        @all_steps ||= {}
      end

      def self.register(step)
        all_steps[step.name] = step
      end

      attr_reader :output_io

      def initialize(process_step)
        @process_step = process_step
        @output_io = StringIO.new("")
      end

      def puts(*a)
        @output_io.puts(*a)
      end

      def output
        @output_io.string
      end

      def attempts
        3
      end

      def delay_between_attempts
        10
      end

      def process
        @process_step.process
      end

      def name
        self.class.name
      end

      def run_with_log
        log(fn: "run") do
          run
        end
      end

      def sleep
        raise Step::Tired
      end

      def fatal!
        raise Step::Fatal
      end

      def log(data, &block)
        Log.log({ ns: "yawl-step_#{name}" }.merge(data), &block)
      end
    end

    class RealStepMissing < Base
      def self.name
        "real_step_missing"
      end

      def run
        raise "The real step is missing"
      end

      def attempts
        0
      end
    end
  end
end
