namespace :debug do
  desc "Show Menu table"
  task show_menus: :environment do
    menus = Menu.all

    rows = menus.map do |menu|
      [
        menu.id,
        menu.menu,           # menu.name じゃなくて menu.menu を使っているようなので注意！
        menu.favorite,
        menu.created_at.strftime("%Y-%m-%d"),
        menu.updated_at.strftime("%Y-%m-%d")
      ]
    end

    table = Terminal::Table.new(
      title: "Menus Table",
      headings: [ "ID", "Menu", "Favorite", "Created At", "Updated At" ],
      rows: rows
    )

    puts table
  end
end
