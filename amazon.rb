require 'rubygems'
require 'logger'
require 'mechanize'

AMAZON_LOGIN = 'https://developer.amazon.com/login.html'

AMAZON_IAP= 'iap/entitlement/'
IAP_GENERAL = 'general/'
IAP_AVAILABILITY = 'availability/'
IAP_DESCRIPTION = 'description/'
IAP_IMAGES = 'multimedia/'
IAP_SUFFIX = 'detail.html?default'
IAP_EDIT= 'edit.html'
IAP_NEW = 'new.html'


mech = Mechanize.new{  |agent|
  # Flickr refreshes after login
  agent.follow_meta_refresh = true
  #agent.log = Logger.new(STDERR)
  agent.user_agent_alias = 'Mac Safari'
}

# Login
def login(mech)
  base_page = mech.get(AMAZON_LOGIN) 
  main_page = base_page.form_with(:name => 'signIn') do |form|
    form.email = AMAZON_EMAIL 
    form.password = AMAZON_PASS
    form.radiobuttons_with(:name => 'create')[1].check
  end.submit
end

def in_app_management(mech, main_page)
  # Get the apps page link
  apps_page = mech.get(AMAZON_APPS_URL)
  in_app_link = apps_page.link_with(:text => "Manage in-app items")

  # Go to In-App management page
  in_app_page = mech.click(in_app_link)
end

# Add new consumable
def add_new(mech, in_app_page, title, sku)
  add_new_link = in_app_page.link_with(:text => "Add an Entitlement")
  add_new_page = mech.click(add_new_link)
  created_item_page = add_new_page.form_with(:action => "/iap/entitlement/general/save.html") do |form|
    form.title = "Test"
    form.vendorSku = "1test"
    form.radiobuttons_with(:name => "contentDeliveryMethod")[1].check
  end.submit
end

# Update an existing item
def get_existing(mech, in_app_page, title)
  # search form
  search_form = in_app_page.forms.find { |f| f.action.include? 'iap_list.html' }
  search_form.searchText = title
  search_results = search_form.submit
  existing_item = mech.click(search_results.links.find { |l| l.to_s.lstrip == title } )
end

def get_item_app_id(mech, in_app_page, title)
  search_form = in_app_page.forms.find { |f| f.action.include? 'iap_list.html' }
  search_form.searchText = title
  search_results = search_form.submit
  item_uri = search_results.links.find { |l| l.text.lstrip == title }.uri
  # Get the item id from the link url
  item_id = item_uri.path.split('/')[-2]
end

def get_app_id(mech, in_app_page)
  app_id = in_app_page.link_with(:text => "Add an Entitlement").uri.path.split('/')[-2]
end

def get_item_description_form(mech, item_id)
  desc_page = mech.get("#{AMAZON_BASE}#{AMAZON_IAP}#{IAP_DESCRIPTION}#{item_id}/#{IAP_SUFFIX}")
  alt_id = desc_page.form_with(:action => '/iap/entitlement/description/submission.html').encryptedItemMetaDataId
  edit_page = mech.get("#{AMAZON_BASE}#{AMAZON_IAP}#{IAP_DESCRIPTION}#{alt_id}/#{IAP_EDIT}")
  desc_form = edit_page.form_with(:action => "/iap/entitlement/description/save.html")
end

def get_item_availability_form(mech, item_id)
  edit_page = mech.get("#{AMAZON_BASE}#{AMAZON_IAP}#{IAP_AVAILABILITY}#{item_id}/#{IAP_EDIT}")
  desc_form = edit_page.form_with(:action => "/iap/entitlement/availability/save.html")
end

def get_item_multimedia_form(mech, item_id)
  edit_page = mech.get("#{AMAZON_BASE}#{AMAZON_IAP}#{IAP_IMAGES}#{item_id}/#{IAP_EDIT}")
  desc_form = edit_page.form_with(:action => "/iap/entitlement/multimedia/save.html")
end

def set_item_description_info(mech, item_id, description, keywords)
  desc_form = get_item_description_form(mech, item_id)
  desc_form['selectedCollectableMetaData.dpShortDescription'] = description
  desc_form['selectedCollectableMetaData.keywordsString'] = keywords
  desc_form.add_field!('save',nil)
  pp desc_form
  desc_form.submit
end

def set_item_availability_info(mech, item_id, price, date)
  price_form = get_item_availability_form(mech, item_id)
  price_form['baseListprice.price'] = price
  price_form['availabilityDate'] = date
  pp price_form
  price_form.submit
end

class AmazonIAP
  attr_accessor :mech, :iap 
  
  AMAZON_BASE = 'https://developer.amazon.com/'
  AMAZON_LOGIN = AMAZON_BASE + 'login.html'
  AMAZON_APPS_URL = AMAZON_BASE + 'myapps.html'
  AMAZON_IAP= 'iap/entitlement/'
  IAP_GENERAL = 'general/'
  IAP_AVAILABILITY = 'availability/'
  IAP_DESCRIPTION = 'description/'
  IAP_IMAGES = 'multimedia/'
  IAP_SUFFIX = 'detail.html?default'
  IAP_EDIT= 'edit.html'
  IAP_NEW = 'new.html'

  def initialize()
    self.mech = Mechanize.new do |agent|
      # Flickr refreshes after login
      agent.follow_meta_refresh = true
      #agent.log = Logger.new(STDERR)
      agent.user_agent_alias = 'Mac Safari'
    end
  end

  # Login
  def login(email, password)
    base_page = self.mech.get(AMAZON_LOGIN) 
    main_page = base_page.form_with(:name => 'signIn') do |form|
      form.email = email 
      form.password = password 
      form.radiobuttons_with(:name => 'create')[1].check
    end.submit
    self.iap = in_app_management(main_page)
  end

  def in_app_management(main_page)
    # Get the apps page link
    apps_page = self.mech.get(AMAZON_APPS_URL)
    in_app_link = apps_page.link_with(:text => "Manage in-app items")

    # Go to In-App management page
    in_app_page = self.mech.click(in_app_link)
  end

  # Add new consumable
  def add_new(title, sku)
    add_new_link = self.iap.link_with(:text => "Add an Entitlement")
    add_new_page = self.mech.click(add_new_link)
    created_item_page = add_new_page.form_with(:action => "/iap/entitlement/general/save.html") do |form|
      form.title = "Test"
      form.vendorSku = "1test"
      form.radiobuttons_with(:name => "contentDeliveryMethod")[1].check
    end.submit
  end

  # Update an existing item
  def get_existing(title)
    # search form
    search_form = self.iap.forms.find { |f| f.action.include? 'iap_list.html' }
    search_form.searchText = title
    search_results = search_form.submit
    existing_item = self.mech.click(search_results.links.find { |l| l.to_s.lstrip == title } )
  end

  def get_item_app_id(title)
    search_form = self.iap.forms.find { |f| f.action.include? 'iap_list.html' }
    search_form.searchText = title
    search_results = search_form.submit
    item_uri = search_results.links.find { |l| l.text.lstrip == title }.uri
    # Get the item id from the link url
    item_id = item_uri.path.split('/')[-2]
  end

  def get_app_id()
    app_id = self.iap.link_with(:text => "Add an Entitlement").uri.path.split('/')[-2]
  end

  def get_item_description_form(item_id)
    desc_page = self.mech.get("#{AMAZON_BASE}#{AMAZON_IAP}#{IAP_DESCRIPTION}#{item_id}/#{IAP_SUFFIX}")
    alt_id = desc_page.form_with(:action => '/iap/entitlement/description/submission.html').encryptedItemMetaDataId
    edit_page = self.mech.get("#{AMAZON_BASE}#{AMAZON_IAP}#{IAP_DESCRIPTION}#{alt_id}/#{IAP_EDIT}")
    desc_form = edit_page.form_with(:action => "/iap/entitlement/description/save.html")
  end

  def get_item_availability_form(item_id)
    edit_page = self.mech.get("#{AMAZON_BASE}#{AMAZON_IAP}#{IAP_AVAILABILITY}#{item_id}/#{IAP_EDIT}")
    desc_form = edit_page.form_with(:action => "/iap/entitlement/availability/save.html")
  end

  def get_item_multimedia_form(item_id)
    edit_page = self.mech.get("#{AMAZON_BASE}#{AMAZON_IAP}#{IAP_IMAGES}#{item_id}/#{IAP_EDIT}")
    desc_form = edit_page.form_with(:action => "/iap/entitlement/multimedia/save.html")
  end

  def set_item_description_info(item_id, description, keywords)
    desc_form = get_item_description_form(item_id)
    desc_form['selectedCollectableMetaData.dpShortDescription'] = description
    desc_form['selectedCollectableMetaData.keywordsString'] = keywords
    desc_form.add_field!('save',nil)
    desc_form.submit
  end

  def set_item_availability_info(item_id, price, date)
    price_form = get_item_availability_form(item_id)
    price_form['baseListprice.price'] = price
    price_form['availabilityDate'] = date
    price_form.submit
  end

  def get_item_description(item_id)
    desc_form = get_item_description_form(self.mech, item_id)
    desc = desc_form['selectedCollectableMetaData.dpShortDescription']
  end
end

amazon_iap = AmazonIAP.new()
main_page = amazon_iap.login(AMAZON_EMAIL, AMAZON_PASS)

puts "App ID: " + amazon_iap.get_app_id()
item_id = amazon_iap.get_item_app_id('Test')
puts "Test Item ID: " + item_id
amazon_iap.set_item_availability_info(item_id, 9.99, '10/11/2012')

pp amazon_iap.get_item_multimedia_form(item_id)

#set_item_description_info(mech, item_id, "Test description", "test darkhorse")
#pp get_item_description(mech, item_id)
#existing_item = get_existing(mech, in_app_page, 'Little Lulu #88')

#pp in_app_page

#created_item_page = add_new(mech, in_app_page, "Test", "1test")
#pp created_item_page
