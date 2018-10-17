require "spec_helper"

class FakeObject
  def self.[](value)
  end
end

describe Yawl::Process do
  before(:each) do
    Yawl::ProcessDefinitions.add :tested do |process|
      process.add_step(:name => "testing")
    end

    @process = Yawl::Process.create(:object_type => "FakeObject", :object_id => 123, :desired_state => "tested")
    @fake_object = FakeObject.new
    allow(FakeObject).to receive(:[]).with(123) { @fake_object }
  end

  it "loads object" do
    expect(@process.object).to eq(@fake_object)
  end
end
