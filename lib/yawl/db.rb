require 'sequel'
require 'yawl/config'

module Yawl
  DB = Sequel.connect(ENV["DATABASE_URL"].gsub('postgresql://', 'postgres://'))

  if Config.log_sequel?
    require 'logger'
    DB.loggers << Logger.new($stdout)
  end

  def self.setup_database_options
    DB.extension :pg_json
    DB.execute("SET bytea_output TO 'escape'")
  end
end

Yawl.setup_database_options
