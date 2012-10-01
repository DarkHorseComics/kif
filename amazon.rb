require 'rubygems'
require 'mechanize'

AMAZON_LOGIN = 'https://developer.amazon.com/login.html'

AMAZON_IAP= 'iap/entitlement/'
IAP_GENERAL = 'general/'
IAP_AVAILABILITY = 'availability/'
IAP_DESCRIPTION = 'description/'
IAP_IMAGES = 'multimedia/'
IAP_SUFFIX = 'detail.html'

mech = Mechanize.new{  |agent|
  # Flickr refreshes after login
  agent.follow_meta_refresh = true
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
  existing = get_existing(mech, in_app_page, title)
  #general_info = 
end

def update_existing_pricing(mech, existing_item, price, date)
  # Update things
end
main_page = login(mech)
in_app_page = in_app_management(mech,main_page)

existing_item = get_existing(mech, in_app_page, 'Little Lulu #88')

#pp in_app_page

#created_item_page = add_new(mech, in_app_page, "Test", "1test")
#pp created_item_page
