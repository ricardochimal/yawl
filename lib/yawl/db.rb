require 'sequel'
require 'yawl/config'

module Yawl
  DB = Sequel.connect(ENV["DATABASE_URL"].gsub('postgresql://', 'postgres://'))
  DB.extension :pg_json
  DB.execute("SET bytea_output TO 'escape'")

  if Config.log_sequel?
    require 'logger'
    DB.loggers << Logger.new($stdout)
  end
end
