$:.unshift(File.expand_path(File.join(File.dirname($0), "../lib")))

require "sequel"

Sequel.connect(ENV["DATABASE_URL"] || "postgres://localhost/yawl_examples")

require "yawl"
require File.dirname(File.expand_path(__FILE__)) + "/steps/scrambled_eggs"

p = Yawl::Process.create(:desired_state => "scrambled_eggs")
p.start

p = Yawl::Process.create(:desired_state => "breakfast")
p.start
