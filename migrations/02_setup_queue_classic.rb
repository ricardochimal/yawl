require "queue_classic"
require "queue_classic/later"

Sequel.migration do
  down do
    QC::Setup.drop
    QC::Later::Setup.drop
  end

  up do
    QC::Setup.create
    QC::Later::Setup.create
  end
end
