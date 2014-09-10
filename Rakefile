require "bundler/gem_tasks"

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new('spec')

task :default => :spec

task :environment do
  @env = ENV['RACK_ENV'] || "development"
  @app = "yawl"
  @dbname = "#{@app}_#{@env}"
  ENV["DATABASE_URL"] ||= "postgres://localhost/#{@dbname}"
end

namespace :db do
  task :reset => :environment do
    system("psql -l | grep -q #{@dbname} && dropdb #{@dbname}")
  end

  desc "Create the database, load the schema, and initialize with the seed data (use db:reset to also drop the db first)"
  task :setup => :environment do
    # Create the database if it does not exist
    system("psql -l | grep -q #{@dbname} || createdb #{@dbname}")

    # Create and run migrations
    require 'yawl/setup'
    Yawl::Setup.create!              unless Yawl::DB.tables.include?(:processes)
    Yawl::Setup.create_queue_classic unless Yawl::DB.tables.include?(:queue_classic_jobs)
  end
end
