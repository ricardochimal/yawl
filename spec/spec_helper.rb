if ENV["CI"]
  raise "ENV[DATABASE_URL] not set" unless ENV["DATABASE_URL"]
else
  ENV["DATABASE_URL"] = "postgres://localhost/yawl_test"
end
ENV["LOG_QUIET"] ||= "1"

require "rspec"
require "yawl"

require "yawl/setup"

Yawl::Setup.create_for_test!

def QC.jobs
  s = "SELECT * FROM queue_classic_jobs"
  [QC::Conn.execute(s)].compact.flatten.
    map {|j| j.reject {|k, v| !%w[q_name method args].include?(k) } }.
    map {|j| j.merge("args" => JSON.parse(j["args"])) }.
    map {|j| j.reject {|k, v| k == "args" && v.empty? } }
end

def QC.later_jobs
  s = "SELECT * FROM queue_classic_later_jobs"
  [QC::Conn.execute(s)].compact.flatten.
    map {|j| j.reject {|k, v| !%w[q_name method args].include?(k) } }.
    map {|j| j.merge("args" => JSON.parse(j["args"])) }.
    map {|j| j.reject {|k, v| k == "args" && v.empty? } }
end

RSpec.configure do |c|
  c.around(:each) do |example|
    Yawl::DB.transaction(:rollback => :always) do
      begin
        QC::Conn.execute("BEGIN")
        example.run
      ensure
        QC::Conn.execute("ROLLBACK")
      end
    end
  end
end

RSpec::Matchers.define :be_queued_for_later do
  match do |step|
    QC.later_jobs.include?("q_name" => "default", "method" => "Yawl::Step.execute", "args" => [step.id])
  end

  failure_message do |step|
    "expected #{step.inspect} to be queued for later in later jobs #{QC.later_jobs}"
  end

  failure_message_when_negated do |step|
    "expected #{step.inspect} to not be queued for later in later jobs #{QC.later_jobs}"
  end
end

RSpec::Matchers.define :be_queued_for_now do
  match do |step|
    QC.jobs.include?("q_name" => "default", "method" => "Yawl::Step.execute", "args" => [step.id])
  end

  failure_message do |step|
    "expected #{step.inspect} to be queued for now in jobs #{QC.jobs}"
  end

  failure_message_when_negated do |step|
    "expected #{step.inspect} to not be queued for now in jobs #{QC.jobs}"
  end
end
