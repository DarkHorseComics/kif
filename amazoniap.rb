require 'rubygems'
require 'logger'
require 'mechanize'
require 'RMagick'

class AmazonIAP < Mechanize
  attr_accessor :iap 
  attr_accessor :amazon_base, :amazon_login, :amazon_apps_url, :amazon_iap
  attr_accessor :iap_general, :iap_availability, :iap_description, :iap_images, :iap_suffix, :iap_edit, :iap_new

  def initialize(config)
    super()
    config.each {|key, value| instance_variable_set("@#{key}", value) }
    self.follow_meta_refresh = true
    #self.log = Logger.new(STDERR)
    self.user_agent_alias = 'Mac Safari'
  end

  # Login
  def login(email, password)
    base_page = self.get(amazon_login)
    main_page = base_page.form_with(:name => 'signIn') do |form|
      form.email = email 
      form.password = password 
      form.radiobuttons_with(:name => 'create')[1].check
    end.submit
    self.iap = in_app_management(main_page)
  end

  # Gets the main in_app_purchase management page
  def in_app_management(main_page)
    # Get the apps page link
    apps_page = self.get(amazon_apps_url)
    in_app_link = apps_page.link_with(:text => "Manage in-app items")

    # Go to In-App management page
    in_app_page = self.click(in_app_link)
  end

  # Add new entitlement 
  def add_new(title, sku)
    add_new_link = self.iap.link_with(:text => "Add an Entitlement")
    add_new_page = self.click(add_new_link)
    created_item_page = add_new_page.form_with(:action => "/iap/entitlement/general/save.html") do |form|
      form.title = "Test"
      form.vendorSku = "1test"
      form.radiobuttons_with(:name => "contentDeliveryMethod")[1].check
    end.submit
  end

  # Get the details page for an existing item 
  def get_existing(title)
    # search form
    search_form = self.iap.forms.find { |f| f.action.include? 'iap_list.html' }
    search_form.searchText = title
    search_results = search_form.submit
    existing_item = self.click(search_results.links.find { |l| l.to_s.lstrip == title } )
  end

  # Get the Amazon ID for an existing item 
  def get_item_app_id(title)
    search_form = self.iap.forms.find { |f| f.action.include? 'iap_list.html' }
    search_form.searchText = title
    search_results = search_form.submit
    item_uri = search_results.links.find { |l| l.text.lstrip == title }.uri
    # Get the item id from the link url
    item_id = item_uri.path.split('/')[-2]
  end

  # Get the Amazon ID for the application
  def get_app_id()
    app_id = self.iap.link_with(:text => "Add an Entitlement").uri.path.split('/')[-2]
  end

  # Gets the item description form. Description form uses a different ID than the item id 
  def get_item_description_form(item_id)
    desc_page = self.get("#{amazon_base}#{amazon_iap}#{iap_description}#{item_id}/#{iap_suffix}")
    alt_id = desc_page.form_with(:action => '/iap/entitlement/description/submission.html').encryptedItemMetaDataId
    edit_page = self.get("#{amazon_base}#{amazon_iap}#{iap_description}#{alt_id}/#{iap_edit}")
    desc_form = edit_page.form_with(:action => "/iap/entitlement/description/save.html")
  end

  # Gets the pricing and availability form
  def get_item_availability_form(item_id)
    edit_page = self.get("#{amazon_base}#{amazon_iap}#{iap_availability}#{item_id}/#{iap_edit}")
    desc_form = edit_page.form_with(:action => "/iap/entitlement/availability/save.html")
  end

  # Gets the image upload form
  def get_item_multimedia_form(item_id)
    edit_page = self.get("#{amazon_base}#{amazon_iap}#{iap_images}#{item_id}/#{iap_edit}")
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

  # Scale a single image into the required format for amazon, requires a PNG
  def set_item_image(item_id, image)
    small_icon = image.crop_resized(114, 114, Magick::NorthGravity)
    large_icon = image.crop_resized(512, 512, Magick::NorthGravity)
    screenshot = image.crop_resized(1280, 720, Magick::NorthGravity)
    set_item_images(item_id, small_icon, large_icon, screenshot, screenshot)
  end

  # Inidividual images must be submitted one by one
  def set_item_images(item_id, small_icon, large_icon, screenshot, purchase_screenshot)
    image_form = get_item_multimedia_form(item_id)
    submit_image_upload(image_form, small_icon, 'small.png', 'ICON')
    submit_image_upload(image_form, large_icon, 'large.png', 'THUMB_AND_BOX')
    submit_image_upload(image_form, screenshot, 'screenshot.png', 'SCREENSHOT')
    submit_image_upload(image_form, purchase_screenshot, 'purch.png', 'PURCHASESHOT')
  end

  # Submit the image form using multipart. assetType must be set to the current image field
  def submit_image_upload(image_form, image, file_name, field_name)
    image_form.enctype = 'multipart/form-data'
    image_form.assetType = field_name 
    image_form.file_uploads_with(:name => field_name) do |f|
      unless f.first.nil?
        f = f.first
        f.mime_type = "image/png"
        f.file_name = file_name
        f.file_data = image.to_blob
      end
    end
    image_form.submit
  end

  # Get the description of an item by item_id
  def get_item_description(item_id)
    desc_form = get_item_description_form(item_id)
    desc = desc_form['selectedCollectableMetaData.dpShortDescription']
  end
end

