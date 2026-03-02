class CreateSolidQueueJobs < ActiveRecord::Migration[7.0]
  def change
    create_table :solid_queue_jobs do |t|
      t.string   :queue,    null: false
      t.string   :job_class
      t.jsonb    :args,     null: false, default: []
      t.integer  :priority, null: false, default: 0
      t.datetime :run_at
      t.datetime :locked_at

      t.timestamps
    end

    add_index :solid_queue_jobs, :queue
    add_index :solid_queue_jobs, :run_at
    add_index :solid_queue_jobs, :priority
  end
end
