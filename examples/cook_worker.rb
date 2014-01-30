#!/usr/bin/env ruby

$:.unshift(File.expand_path(File.join(File.dirname($0), "../lib")))

ENV["DATABASE_URL"] ||= "postgres://localhost/yawl_examples"

require "yawl"
require "yawl/worker"

require File.dirname(File.expand_path(__FILE__)) + "/steps/scrambled_eggs"

$stdout.sync = true
Yawl::Worker.start
