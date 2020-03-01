#!/usr/bin/env ruby

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'nokogiri'
  gem 'curb'
end

require 'nokogiri'
require 'curb'
require 'csv'

START_PAGE = ARGV.first
CSV_FILE = ARGV.last
TIME_TO_SLEEP_TO_PREVENT_TRACKING = 0.1

def main
  catalog_pages_links = fetch_catalog_pages_links
  total_pages_count = catalog_pages_links.count

  data = []
  catalog_pages_links.each_with_index do |catalog_page_url, page_number|
    catalog_page = Nokogiri::HTML(Curl.get(catalog_page_url).body_str)
    products_links = catalog_page.xpath('//*[@id="product_list"]//a[@class="product-name"]')

    total_count = products_links.count

    products_links.each_with_index do |el, index|
      product_url = el.attr('href')
      product_name = el.attr('title')

      print("Processing page ##{page_number + 1} of ##{total_pages_count}, product: ##{index + 1} of ##{total_count}   \r")
      data += product_info(product_url, product_name)
    end

  end

  fill_csv(data)

  puts("Finished")
end

def fetch_catalog_pages_links
  pages_of_catalog = [START_PAGE]
  doc = Nokogiri::HTML(Curl.get(START_PAGE).body_str)

  total_products = doc.at_css('[id="center_column"] .heading-counter').text.to_i
  products_per_page = doc.xpath('//*[@id="product_list"]/li').count
  page_count = (total_products / products_per_page.to_f).ceil

  puts("Total items count for the catgory: #{total_products}\n")
  return pages_of_catalog if page_count == 1

  pages_of_catalog + (2..page_count).map { |number| "#{START_PAGE}?p=#{number}" }
end

def product_info(url, product_name)
  doc = Nokogiri::HTML(Curl.get(url).body_str)
  doc.encoding = 'utf-8'
  items = []
  logo = doc.xpath('//*[@id="bigpic"]').first.attr('src')
  doc.xpath('//*[@id="attributes"]/fieldset/div/ul/li').each do |el|
    item = {}
    item['Price'] = el.xpath('label/span[@class="price_comb"]').first.content
    item['Weight'] = el.xpath('label/span[@class="radio_label"]').first.content
    item['Logo'] = logo
    item['Title'] = product_name
    items << item
    sleep(TIME_TO_SLEEP_TO_PREVENT_TRACKING)
  end
  items
end

def fill_csv(data)
  puts("\nWriting to csv...")
  CSV.open("#{CSV_FILE}", "w") do |csv|
    csv << ["Name", "Price", "Image"]
    data.each do |item|
      csv << [item["Title"] + " - " + item["Weight"], item["Price"], item["Logo"] ]
    end
  end
end
main