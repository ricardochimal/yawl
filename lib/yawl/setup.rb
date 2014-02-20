require 'sequel'

require 'yawl/db'

Sequel.extension :migration

module Yawl
  module Setup
    extend self

    MIGRATION = Sequel.migration do
      change do
        create_table(:processes) do
          primary_key :id
          String :desired_state, :text=>true, :null=>false
          String :state, :default=>"pending", :text=>true, :null=>false
          DateTime :created_at
          String :name, :text=>true
          json :config
          String :request_id, :text=>true
          String :specified_attributes
        end

        create_table(:steps) do
          primary_key :id
          Integer :process_id, :null=>false
          Integer :seq, :null=>false
          String :name, :text=>true, :null=>false
          String :state, :default=>"pending", :text=>true, :null=>false

          index [:process_id]
        end

        create_table(:step_attempts) do
          primary_key :id
          Integer :step_id, :null=>false
          File :output
          DateTime :started_at
          DateTime :completed_at

          index [:step_id]
        end
      end
    end

    def create!
      MIGRATION.apply(DB, :up)
    end

    def destroy!
      MIGRATION.apply(DB, :down)
    end

    def create_for_test!
      if DB.tables.include?(:processes)
        destroy!
      end
      create!

      require "queue_classic"
      QC::Setup.drop
      QC::Setup.create

      require "queue_classic/later"
      QC::Later::Setup.drop
      QC::Later::Setup.create
    end
  end
end
