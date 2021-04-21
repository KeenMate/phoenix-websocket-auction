defmodule BiddingPoc.DataPopulation do
  alias BiddingPoc.Database.User
  alias BiddingPoc.Database.AuctionItemCategory

  def insert_users() do
    dummy_users()
    |> Enum.map(fn user ->
      User.create_user(user.username, user.display_name, user.password, user.is_admin)
    end)
  end

  def insert_categories() do
    dummy_categories()
    |> Enum.map(fn category -> AuctionItemCategory.create_category(category) end)
  end

  defp dummy_users() do
    [
      %{username: "user001", display_name: "Norman, Risa", password: "1234", is_admin: true},
      %{username: "user002", display_name: "Melton, Karina", password: "1234", is_admin: true},
      %{username: "user003", display_name: "Castro, Camilla", password: "1234", is_admin: true},
      %{username: "user004", display_name: "Cherry, Elijah", password: "1234", is_admin: true},
      %{username: "user005", display_name: "Contreras, Barclay", password: "1234", is_admin: true},
      %{username: "user006", display_name: "Cruz, Lilah", password: "1234", is_admin: true},
      %{username: "user007", display_name: "Goodwin, Gail", password: "1234", is_admin: true},
      %{username: "user008", display_name: "Padilla, Jessica", password: "1234", is_admin: true},
      %{username: "user009", display_name: "Rojas, Chava", password: "1234", is_admin: true},
      %{username: "user010", display_name: "Mccoy, Alden", password: "1234", is_admin: true},
      %{username: "user011", display_name: "Cunningham, Germane", password: "1234", is_admin: false},
      %{username: "user012", display_name: "Cannon, Olympia", password: "1234", is_admin: false},
      %{username: "user013", display_name: "Bates, Tarik", password: "1234", is_admin: false},
      %{username: "user014", display_name: "Ryan, Carl", password: "1234", is_admin: false},
      %{username: "user015", display_name: "Ingram, Melodie", password: "1234", is_admin: false},
      %{username: "user016", display_name: "Levine, Devin", password: "1234", is_admin: false},
      %{username: "user017", display_name: "Montgomery, Madison", password: "1234", is_admin: false},
      %{username: "user018", display_name: "Bowen, Buffy", password: "1234", is_admin: false},
      %{username: "user019", display_name: "Reyes, Frances", password: "1234", is_admin: false},
      %{username: "user020", display_name: "Nicholson, Rashad", password: "1234", is_admin: false},
      %{username: "user021", display_name: "Bryan, Stella", password: "1234", is_admin: false},
      %{username: "user022", display_name: "Blair, Fredericka", password: "1234", is_admin: false},
      %{username: "user023", display_name: "Richmond, Nash", password: "1234", is_admin: false},
      %{username: "user024", display_name: "Barron, Zephania", password: "1234", is_admin: false},
      %{username: "user025", display_name: "Banks, Hyatt", password: "1234", is_admin: false},
      %{username: "user026", display_name: "Murray, Christen", password: "1234", is_admin: false},
      %{username: "user027", display_name: "Adams, Xerxes", password: "1234", is_admin: false},
      %{username: "user028", display_name: "Oliver, Geoffrey", password: "1234", is_admin: false},
      %{username: "user029", display_name: "Atkins, Brenden", password: "1234", is_admin: false},
      %{username: "user030", display_name: "Barrera, Gloria", password: "1234", is_admin: false},
      %{username: "user031", display_name: "Sanford, Amaya", password: "1234", is_admin: false},
      %{username: "user032", display_name: "Maxwell, George", password: "1234", is_admin: false},
      %{username: "user033", display_name: "Pennington, Aline", password: "1234", is_admin: false},
      %{username: "user034", display_name: "Holloway, Logan", password: "1234", is_admin: false},
      %{username: "user035", display_name: "Meadows, Vanna", password: "1234", is_admin: false},
      %{username: "user036", display_name: "Bender, Alyssa", password: "1234", is_admin: false},
      %{username: "user037", display_name: "Sanford, Judith", password: "1234", is_admin: false},
      %{username: "user038", display_name: "Bernard, Dominique", password: "1234", is_admin: false},
      %{username: "user039", display_name: "Boyer, Carla", password: "1234", is_admin: false},
      %{username: "user040", display_name: "Trevino, Stewart", password: "1234", is_admin: false},
      %{username: "user041", display_name: "Castaneda, Damian", password: "1234", is_admin: false},
      %{username: "user042", display_name: "Brady, Oleg", password: "1234", is_admin: false},
      %{username: "user043", display_name: "Owens, Autumn", password: "1234", is_admin: false},
      %{username: "user044", display_name: "Macdonald, Gavin", password: "1234", is_admin: false},
      %{username: "user045", display_name: "Alvarez, Calista", password: "1234", is_admin: false},
      %{username: "user046", display_name: "Haney, Benjamin", password: "1234", is_admin: false},
      %{username: "user047", display_name: "Gould, Lydia", password: "1234", is_admin: false},
      %{username: "user048", display_name: "Pollard, Beau", password: "1234", is_admin: false},
      %{username: "user049", display_name: "Sexton, Hollee", password: "1234", is_admin: false},
      %{username: "user050", display_name: "West, Ulric", password: "1234", is_admin: false},
      %{username: "user051", display_name: "Mullen, Casey", password: "1234", is_admin: false},
      %{username: "user052", display_name: "Burton, Ivor", password: "1234", is_admin: false},
      %{username: "user053", display_name: "Holland, Ferris", password: "1234", is_admin: false},
      %{username: "user054", display_name: "Lara, Kevin", password: "1234", is_admin: false},
      %{username: "user055", display_name: "Hendrix, Bo", password: "1234", is_admin: false},
      %{username: "user056", display_name: "Dickerson, Audrey", password: "1234", is_admin: false},
      %{username: "user057", display_name: "Morrow, Alice", password: "1234", is_admin: false},
      %{username: "user058", display_name: "Larsen, Zeph", password: "1234", is_admin: false},
      %{username: "user059", display_name: "Henson, Ronan", password: "1234", is_admin: false},
      %{username: "user060", display_name: "Sargent, Maxine", password: "1234", is_admin: false},
      %{username: "user061", display_name: "Avila, Shad", password: "1234", is_admin: false},
      %{username: "user062", display_name: "Valentine, Hayes", password: "1234", is_admin: false},
      %{username: "user063", display_name: "Moran, Driscoll", password: "1234", is_admin: false},
      %{username: "user064", display_name: "Noble, Allen", password: "1234", is_admin: false},
      %{username: "user065", display_name: "Lawrence, Jennifer", password: "1234", is_admin: false},
      %{username: "user066", display_name: "Nicholson, Stella", password: "1234", is_admin: false},
      %{username: "user067", display_name: "Matthews, Clark", password: "1234", is_admin: false},
      %{username: "user068", display_name: "Stout, Stephen", password: "1234", is_admin: false},
      %{username: "user069", display_name: "Skinner, Nasim", password: "1234", is_admin: false},
      %{username: "user070", display_name: "Collins, Noble", password: "1234", is_admin: false},
      %{username: "user071", display_name: "Huber, Cheryl", password: "1234", is_admin: false},
      %{username: "user072", display_name: "Hurst, Dean", password: "1234", is_admin: false},
      %{username: "user073", display_name: "Weaver, Honorato", password: "1234", is_admin: false},
      %{username: "user074", display_name: "Hendricks, Orla", password: "1234", is_admin: false},
      %{username: "user075", display_name: "Wells, Lillith", password: "1234", is_admin: false},
      %{username: "user076", display_name: "Bean, Sierra", password: "1234", is_admin: false},
      %{username: "user077", display_name: "Mckay, Patrick", password: "1234", is_admin: false},
      %{username: "user078", display_name: "Savage, Aretha", password: "1234", is_admin: false},
      %{username: "user079", display_name: "Stein, Lesley", password: "1234", is_admin: false},
      %{username: "user080", display_name: "Rush, Vielka", password: "1234", is_admin: false},
      %{username: "user081", display_name: "Espinoza, Leila", password: "1234", is_admin: false},
      %{username: "user082", display_name: "York, Galvin", password: "1234", is_admin: false},
      %{username: "user083", display_name: "Tyson, Basil", password: "1234", is_admin: false},
      %{username: "user084", display_name: "Joyner, Hop", password: "1234", is_admin: false},
      %{username: "user085", display_name: "Sims, Stacey", password: "1234", is_admin: false},
      %{username: "user086", display_name: "Foster, Bethany", password: "1234", is_admin: false},
      %{username: "user087", display_name: "Glenn, Fuller", password: "1234", is_admin: false},
      %{username: "user088", display_name: "Doyle, Jessica", password: "1234", is_admin: false},
      %{username: "user089", display_name: "Day, Aristotle", password: "1234", is_admin: false},
      %{username: "user090", display_name: "Mcmahon, Moses", password: "1234", is_admin: false},
      %{username: "user091", display_name: "Buck, Haley", password: "1234", is_admin: false},
      %{username: "user092", display_name: "Obrien, Sonia", password: "1234", is_admin: false},
      %{username: "user093", display_name: "Lang, Cullen", password: "1234", is_admin: false},
      %{username: "user094", display_name: "Hunter, Xander", password: "1234", is_admin: false},
      %{username: "user095", display_name: "Guerrero, Armando", password: "1234", is_admin: false},
      %{username: "user096", display_name: "Salinas, Julian", password: "1234", is_admin: false},
      %{username: "user097", display_name: "Palmer, Martina", password: "1234", is_admin: false},
      %{username: "user098", display_name: "Robbins, Alexander", password: "1234", is_admin: false},
      %{username: "user099", display_name: "Vance, Ulric", password: "1234", is_admin: false},
      %{username: "user100", display_name: "May, Christopher", password: "1234", is_admin: false}
    ]
  end

  defp dummy_categories() do
    [
      "Furniture",
      "Paintings",
      "Jewellery"
    ]
  end
end
