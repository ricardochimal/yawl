require "spec_helper"

describe Yawl::Step do
  let(:process) {
    p = Yawl::Process.create(:desired_state => "tested")
    p.start
    p
  }
  let(:step) { process.unfinished_steps.first }

  before do
    Yawl::ProcessDefinitions.add :tested do |process|
      process.add_step(:name => "testing")
    end
  end

  def define_successful_step
    Yawl::Steps.step :testing do
      def run
        puts "I worked"
      end
    end
  end

  def define_failing_step
    Yawl::Steps.step :testing do
      def run
        puts "I started"
        raise "I failed"
      end
    end
  end

  def define_sigterm_step
    Yawl::Steps.step :testing do
      def run
        puts "I started"
        raise SignalException.new("SIGTERM")
      end
    end
  end

  def define_one_shot_failing_step
    Yawl::Steps.step :testing do
      def run
        puts "I started"
        raise "I failed"
      end

      def attempts
        1
      end
    end
  end

  def define_fatal_step
    Yawl::Steps.step :testing do
      def run
        puts "I started"
        raise Yawl::Step::Fatal
      end
    end
  end

  def define_sleepy_step
    Yawl::Steps.step :testing do
      def run
        puts "I started"
        sleep
      end
    end
  end

  def define_one_shot_sleepy_step
    Yawl::Steps.step :testing do
      def run
        puts "I started"
        sleep
      end

      def attempts
        1
      end
    end
  end

  describe ".execute" do
    before do
      define_successful_step
    end

    it "executes a single step by id" do
      Yawl::Step.execute(step.id)

      step.reload.state.should == "completed"
    end
  end

  describe ".restart_interrupted" do
    before do
      define_successful_step
    end

    it "starts steps in the interrupted state" do
      step.update(:state => "interrupted")

      Yawl::Step.restart_interrupted

      step.should be_queued_for_now
    end
  end

  describe "#start" do
    before do
      define_successful_step
    end

    it "enqueues the step for immediate execution" do
      step.start

      step.should be_queued_for_now
    end

    it "resets state to pending" do
      step.update(:state => "failed")

      step.start

      step.state.should == "pending"
    end
  end

  context "running a successful step" do
    before do
      define_successful_step
    end

    it "sets state to completed" do
      step.execute

      step.state.should == "completed"
    end

    it "notifies the process of completion" do
      step.process.should_receive(:step_finished)

      step.execute
    end

    it "captures output" do
      step.execute

      step.attempts.first.output.should == "I worked\n"
    end
  end

  context "running a failing step" do
    context "that has attempts remaining" do
      before do
        define_failing_step
      end

      it "sets state to pending" do
        step.execute

        step.state.should == "pending"
      end

      it "does not notify the process of failure" do
        step.process.should_not_receive(:step_failed)

        step.execute
      end

      it "is queued for retry" do
        step.execute

        step.should be_queued_for_later
      end

      it "captures output" do
        step.execute

        step.attempts.first.output.should =~ /\AI started\n\n\n---\nCAUGHT ERROR: I failed\n.*:in `.*'/ # backtrace
      end
    end

    context "running a fatal step" do
      context "that has attempts remaining" do
        before do
          define_fatal_step
        end

        it "sets state to pending" do
          expect {
            step.execute
          }.to raise_error(Yawl::Step::Fatal)

          step.state.should == "failed"
        end

        it "does not notify the process of failure" do
          step.process.should_receive(:step_failed)

          expect {
            step.execute
          }.to raise_error(Yawl::Step::Fatal)
        end

        it "is not queued for retry" do
          expect {
            step.execute
          }.to raise_error(Yawl::Step::Fatal)

          step.should_not be_queued_for_later
        end

        it "captures output" do
          expect {
            step.execute
          }.to raise_error(Yawl::Step::Fatal)

          step.attempts.first.output.should =~ /\AI started\n\n\n---\nCAUGHT ERROR: Fatal error in step\n.*:in `.*'/ # backtrace
        end
      end
    end

    context "that has no attempts remaining" do
      before do
        define_one_shot_failing_step
      end

      it "passes the error through" do
        expect {
          step.execute
        }.to raise_error("I failed")
      end

      it "sets state to failed" do
        expect { step.execute }.to raise_error

        step.state.should == "failed"
      end

      it "notifies the process of failure" do
        step.process.should_receive(:step_failed)

        expect { step.execute }.to raise_error
      end

      it "is not queued for retry" do
        expect { step.execute }.to raise_error

        step.should_not be_queued_for_later
      end

      it "captures output" do
        expect { step.execute }.to raise_error

        step.attempts.first.output.should =~ /\AI started\n\n\n---\nCAUGHT ERROR: I failed\n.*:in `.*'/
      end
    end

    context "that fails due to SIGTERM" do
      before do
        define_sigterm_step
      end

      it "passes the error through" do
        expect {
          step.execute
        }.to raise_error("SIGTERM")
      end

      it "sets state to interrupted" do
        expect { step.execute }.to raise_error

        step.state.should == "interrupted"
      end

      it "does not notify the process of failure" do
        step.process.should_not_receive(:step_failed)

        expect { step.execute }.to raise_error
      end

      it "is not queued for retry" do
        expect { step.execute }.to raise_error

        step.should_not be_queued_for_later
      end

      it "captures output" do
        expect { step.execute }.to raise_error

        step.attempts.first.output.should =~ /\AI started\n\n\n---\nCAUGHT ERROR: SIGTERM\n.*:in `.*'/ # backtrace
      end
    end
  end

  context "running a sleepy process" do
    context "that has attempts remaining" do
      before do
        define_sleepy_step
      end

      it "sets state to pending" do
        step.execute

        step.state.should == "pending"
      end

      it "does not notify the process of failure" do
        step.process.should_not_receive(:step_failed)

        step.execute
      end

      it "is queued for retry" do
        step.execute

        step.should be_queued_for_later
      end

      it "captures output" do
        step.execute

        step.attempts.first.output.should =~ /\AI started\n\n\n---\nCAUGHT ERROR: Step slept\n.*:in `.*'/ # backtrace
      end
    end

    context "that has no attempts remaining" do
      before do
        define_one_shot_sleepy_step
      end

      it "passes the error through" do
        expect {
          step.execute
        }.to raise_error(Yawl::Step::Tired)
      end

      it "sets state to failed" do
        expect { step.execute }.to raise_error

        step.state.should == "failed"
      end

      it "notifies the process of failure" do
        step.process.should_receive(:step_failed)

        expect { step.execute }.to raise_error
      end

      it "is not queued for retry" do
        expect { step.execute }.to raise_error

        step.should_not be_queued_for_later
      end

      it "captures output" do
        expect { step.execute }.to raise_error

        step.attempts.first.output.should =~ /\AI started\n\n\n---\nCAUGHT ERROR: Step slept\n.*:in `.*'/ # backtrace
      end
    end
  end
end
