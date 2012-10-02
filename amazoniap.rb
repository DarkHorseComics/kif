require 'rubygems'
require 'logger'
require 'mechanize'

class AmazonIAP
  attr_accessor :mech, :iap 
  attr_accessor :amazon_base, :amazon_login, :amazon_apps_url, :amazon_iap
  attr_accessor :iap_general, :iap_availability, :iap_description, :iap_images, :iap_suffix, :iap_edit, :iap_new

  def initialize(config)
    config.each {|key, value| instance_variable_set("@#{key}", value) }
    self.mech = Mechanize.new do |agent|
      agent.follow_meta_refresh = true
      #agent.log = Logger.new(STDERR)
      agent.user_agent_alias = 'Mac Safari'
    end
  end

  # Login
  def login(email, password)
    base_page = self.mech.get(amazon_login) 
    main_page = base_page.form_with(:name => 'signIn') do |form|
      form.email = email 
      form.password = password 
      form.radiobuttons_with(:name => 'create')[1].check
    end.submit
    self.iap = in_app_management(main_page)
  end

  def in_app_management(main_page)
    # Get the apps page link
    apps_page = self.mech.get(amazon_apps_url)
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
    desc_page = self.mech.get("#{amazon_base}#{amazon_iap}#{iap_description}#{item_id}/#{iap_suffix}")
    alt_id = desc_page.form_with(:action => '/iap/entitlement/description/submission.html').encryptedItemMetaDataId
    edit_page = self.mech.get("#{amazon_base}#{amazon_iap}#{iap_description}#{alt_id}/#{iap_edit}")
    desc_form = edit_page.form_with(:action => "/iap/entitlement/description/save.html")
  end

  def get_item_availability_form(item_id)
    edit_page = self.mech.get("#{amazon_base}#{amazon_iap}#{iap_availability}#{item_id}/#{iap_edit}")
    desc_form = edit_page.form_with(:action => "/iap/entitlement/availability/save.html")
  end

  def get_item_multimedia_form(item_id)
    edit_page = self.mech.get("#{amazon_base}#{amazon_iap}#{iap_images}#{item_id}/#{iap_edit}")
    desc_form = edit_page.form_with(:action => "/iap/entitlement/multimedia/save.html")
  end

  def set_item_description(item_id, description, keywords)
    desc_form = get_item_description_form(item_id)
    desc_form['selectedCollectableMetaData.dpShortDescription'] = description
    desc_form['selectedCollectableMetaData.keywordsString'] = keywords
    desc_form.add_field!('save',nil)
    desc_form.submit
  end

  def set_item_availability(item_id, price, date)
    price_form = get_item_availability_form(item_id)
    price_form['baseListprice.price'] = price
    price_form['availabilityDate'] = date
    price_form.submit
  end

  def set_item_images(item_id, small_icon, large_icon, screenshot, purchase_screenshot)
    image_form = get_item_multimedia_form(item_id)
    image_form.ICON = small_icon
    image_form.THUMB_AND_BOX= large_icon 
    image_form.SCREENSHOT= screenshot 
    image_form.PURCHASESHOT= purchase_screenshot
    pp image_form
    image_form.submit
  end

  def get_item_description(item_id)
    desc_form = get_item_description_form(self.mech, item_id)
    desc = desc_form['selectedCollectableMetaData.dpShortDescription']
  end
end

