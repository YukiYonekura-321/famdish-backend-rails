namespace :debug do
  desc "Show User table"
  task show_users: :environment do
    users = User.all

    rows = users.map do |user|
      [
        user.id,
        user.firebase_uid,
        user.created_at.strftime("%Y-%m-%d"),
        user.updated_at.strftime("%Y-%m-%d")
      ]
    end

    table = Terminal::Table.new(
      title: "User Table",
      headings: [ "ID", "Firebase_uid", "Created At", "Updated At" ],
      rows: rows
    )

    puts table
  end
end
