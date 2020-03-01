require 'nokogiri'
require 'curb'
require 'csv'

START_PAGE = ARGV.first
CSV_FILE = ARGV.last

def main
  server_boards = []
  main_page = START_PAGE
  catalog_pages_links(main_page).each do |catalog_page_url|
    catalog_page = Nokogiri::HTML(Curl.get(catalog_page_url).body_str)
    server_boards_links = catalog_page.search("h2.nombre-producto-list a.product-name")
    server_boards_urls = server_boards_links.map { |el| el.attr 'href' }.uniq
    server_boards_names = server_boards_links.map { |el| el.attr 'title' }.uniq
    server_boards_urls.each_with_index do |server_board_url, index|
      board_name = server_boards_names[index]
      server_boards.concat ( server_board_info(server_board_url, board_name))
    end
    CSV.open("#{CSV_FILE}", "w") do |csv|
      csv << ["Name", "Price", "Image"]
      server_boards.each do |item|
        csv << [item["Title"] + " - " + item["Weight"], item["Price"], item["Logo"] ]
      end

    end
  end
end

def catalog_pages_links(main_page)
  pages_of_catalog = [main_page]
  doc = Nokogiri::HTML(Curl.get(main_page).body_str)
  link_to_other_pages = doc.xpath("//li[@class='next']/a").map { |el| el.attr 'href' }
  pages_of_catalog += link_to_other_pages.uniq
end

def server_board_info(url, name)
  doc = Nokogiri::HTML(Curl.get(url).body_str)
  doc.encoding = 'utf-8'
  items = []
  logo = doc.search("a.fancybox img.replace-2x").map { |el| el.attr 'src' }.first
  node = doc.search("ul.attribute_radio_list li").each do |el|
    item = {}
    item['Price'] = el.search("label.label_comb_price span.price_comb").map { |el| el.content }.first
    item['Weight'] = el.search("label.label_comb_price span.radio_label").map { |el| el.content }.first
    item['Logo'] = logo
    item['Title'] = name
    items.push(item)
  end
  items
end

main