#!/usr/bin/env ruby

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'nokogiri'
  gem 'curb'
  # gem 'pry'
end

require 'nokogiri'
require 'curb'
require 'csv'
# require 'pry'

START_PAGE = ARGV.first
CSV_FILE = ARGV.last

def main
  server_boards = []
  catalog_pages_links = fetch_catalog_pages_links
  total_pages_count = catalog_pages_links.count
  catalog_pages_links.each_with_index do |catalog_page_url, page_number|
    catalog_page = Nokogiri::HTML(Curl.get(catalog_page_url).body_str)
    # binding.pry
    server_boards_links = catalog_page.search("h2.nombre-producto-list a.product-name")
    total_count = server_boards_links.count
    server_boards_links.each_with_index do |el, index|
      server_board_url = el.attr('href')
      board_name = el.attr('title')

      print("Processing page ##{page_number + 1} of ##{total_pages_count}, product: ##{index + 1} of ##{total_count}     \r")
      server_boards += server_board_info(server_board_url, board_name)
    end
    CSV.open("#{CSV_FILE}", "w") do |csv|
      csv << ["Name", "Price", "Image"]
      server_boards.each do |item|
        csv << [item["Title"] + " - " + item["Weight"], item["Price"], item["Logo"] ]
      end

    end
  end
end

def fetch_catalog_pages_links
  pages_of_catalog = [START_PAGE]
  doc = Nokogiri::HTML(Curl.get(START_PAGE).body_str)

  total_products = doc.at_css('[id="center_column"] .heading-counter').text.to_i
  products_per_page = doc.at_css('.product_list').children.count
  page_count = (total_products / products_per_page.to_f).ceil

  puts "Total items count for the catgory: #{total_products}\n"
  return pages_of_catalog if page_count == 1

  pages_of_catalog + (2..page_count).map { |number| "#{START_PAGE}?p=#{number}" }
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
    items << item
  end
  items
end

main