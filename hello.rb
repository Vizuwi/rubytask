require 'nokogiri'
require 'open-uri'
require 'json'

def main
  server_boards = {}
  main_page = "http://www.citilink.ru/catalog/computers_and_notebooks/servers_and_net_equipments/server_mbs/?available=1&status=55395790&p=1"
  catalog_pages_links( main_page ).each do |catalog_page_url|
   # puts catalog_page_url
    catalog_page = Nokogiri::HTML( open URI.join( main_page, catalog_page_url ) )
   # puts catalog_page
    server_boards_links = catalog_page.search("span.h3 a.link_gtm-js")
   # puts server_boards_links
    server_boards_urls  = server_boards_links.map {|el| el.attr 'href'}.uniq
    server_boards_names = server_boards_links.map {|el| el.attr 'title'}.uniq
   # puts "server_boards_urls"
   # puts server_boards_urls
    server_boards_urls.each_with_index do |server_board_url, index|
      board_name = server_boards_names[index]
      server_boards[board_name] = server_board_info(server_board_url)
    end
#puts server_boards
    IO.write('citilink.json', JSON.pretty_generate(server_boards))
  end
end

def catalog_pages_links( main_page )
  pages_of_catalog = [main_page]
  doc = Nokogiri::HTML( open main_page )

  # because the same buttons on the bottom of main page V
  link_to_other_pages = doc.xpath("//li[@class='next']/a").map { |el| el.attr 'href' }
  pages_of_catalog += link_to_other_pages.uniq
end

def server_board_info( url )
  doc = Nokogiri::HTML( open url )
  doc.encoding = 'utf-8'
  server_board = {}
  product_features = doc.css('table.product_features tr')
  server_board_properties = ['Количество сокетов',
                             'Слотов памяти DDR3',
                             'Максимальный объем оперативной памяти',
                             'Слоты расширения']

  # Property bust
  product_features.each do |node|
    property_name = node.css('th span').text
    if server_board_properties.include?(property_name)
      server_board[property_name] = node.css('td').text
    end
  end

  # it's a very bit hacky way
  server_board['Цена'] = doc.css('div[class *="line-block product_actions"] span.price ins.num').text
  server_board
end

main