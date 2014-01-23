Sequel.migration do
  change do
    create_table(:processes) do
      primary_key :id
      String :desired_state, :text=>true, :null=>false
      String :state, :default=>"pending", :text=>true, :null=>false
      DateTime :created_at
      String :name, :text=>true
      String :config
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
