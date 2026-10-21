class AddLocationToEventTypes < ActiveRecord::Migration[8.1]
  def change
    add_column :event_types, :location, :string
  end
end
