require 'rubygems'
require 'mechanize'

AMAZON_LOGIN = 'https://developer.amazon.com/login.html'

mech = Mechanize.new{  |agent|
  # Flickr refreshes after login
  agent.follow_meta_refresh = true
}

# Login
mech.get(AMAZON_LOGIN) do |page|
  base_page = page.form_with(:name => 'signIn') do |form|
    form.email = AMAZON_EMAIL 
    form.password = AMAZON_PASS
    form.radiobuttons_with(:name => 'create')[1].check
  end.submit

  print base_page.links
end

