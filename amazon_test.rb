require 'yaml'
require './amazoniap'
require 'RMagick'


CONFIG = YAML.load_file("config/config.yml")

amazon_iap = AmazonIAP.new(CONFIG)
main_page = amazon_iap.login(CONFIG['amazon_email'], CONFIG['amazon_pass'])

puts "App ID: " + amazon_iap.get_app_id()
item_id = amazon_iap.get_item_app_id('Test')
puts "Test Item ID: " + item_id
#pp amazon_iap.set_item_image(item_id,Magick::Image.read('starwars.png').first)
#amazon_iap.set_item_availability(item_id, 9.99, '10/11/2012')

#pp amazon_iap.get_item_multimedia_form(item_id)

#set_item_description_info(mech, item_id, "Test description", "test darkhorse")
pp amazon_iap.get_item_description(item_id)
#existing_item = get_existing(mech, in_app_page, 'Little Lulu #88')

#pp in_app_page

#created_item_page = add_new(mech, in_app_page, "Test", "1test")
#pp created_item_page
