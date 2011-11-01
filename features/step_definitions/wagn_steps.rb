
require 'uri'
require 'cgi'
require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "paths")) 

Given /^I log in as (.+)$/ do |user_card_name|
  # FIXME: define a faster simulate method?
  @current_user = Card[user_card_name].extension
  visit "/account/signin"
  fill_in("login", :with=> @current_user.email )
  fill_in("password", :with=> @current_user.login.split("_")[0]+"_pass")
  click_button("Sign me in")
  page.should have_content("My Card: #{user_card_name}")
end

Given /^I log out/ do
  visit "/"
  click_link("Sign out")
  page.should_not have_content("My Card")
end

Given /^the card (.*) contains "([^\"]*)"$/ do |cardname, content|
  #webrat.simulate do
    User.as(:wagbot) do
      card = Card.fetch_or_create cardname
      card.content = content
      card.save!
    end
  #end
end

Given /^the pointer (.*) contains "([^\"]*)"$/ do |cardname, content|
  step "the card #{cardname} contains \"#{content}\"" 
end

Given /I harden "([^\"]*)"/ do |cardname|
  Card[cardname].update_attribute :extension_type, ""
end

When /^(.*) edits? "([^\"]*)"$/ do |username, cardname|
  logged_in_as(username) do
    visit "/card/edit/#{cardname.to_cardname.to_url_key}"
  end
end
  
When /^(.*) edits? "([^\"]*)" setting (.*) to "([^\"]*)"$/ do |username, cardname, field, content|
  logged_in_as(username) do
    visit "/card/edit/#{cardname.to_cardname.to_url_key}"
    fill_in_hidden_or_not 'card[content]', :with=>content 
    click_button("Save")
    match_content = content.gsub(/\[\[|\]\]/,'')  #link markup won't show up in view.
    response.should have_content(match_content)
  end
end    
                   
When /^(.*) edits? "([^\"]*)" with plusses:/ do |username, cardname, plusses|
  logged_in_as(username) do  
    visit "/card/edit/#{cardname.to_cardname.to_url_key}"       
    plusses.hashes.first.each do |name, content|
      fill_in_hidden_or_not "cards[#{(cardname+'+'+name).to_cardname.pre_cgi}][content]", :with=>content
    end
    click_button("Save")
  end
end
     
When /^(.*) creates?\s*a?\s*([^\s]*) card "(.*)" with content "(.*)"$/ do |username, cardtype, cardname, content|
  create_card(username, cardtype, cardname, content) do  
    content.gsub!(/\\n/,"\n") 
    fill_in_hidden_or_not("card[content]", :with=>content)
  end
end    

When /^(.*) creates?\s*a?\s*([^\s]*) card "(.*)" with content$/ do |username, cardtype, cardname, content|
  create_card(username, cardtype, cardname, content) do   
    fill_in_hidden_or_not("card[content]", :with=>content)
  end
end    

When /^(.*) creates?\s*([^\s]*) card "([^"]*)"$/ do |username, cardtype, cardname|
  create_card(username,cardtype,cardname)
end    

When /^(.*) creates?\s*([^\s]*) card "([^"]*)" with plusses:$/ do |username,cardtype,cardname,plusses|
  create_card(username,cardtype,cardname) do
    plusses.hashes.first.each do |name, content|
      fill_in_hidden_or_not "cards[~plus~#{name}][content]", :with=>content
    end
  end
end
   
When /^(.*) deletes? "([^\"]*)"$/ do |username, cardname|
  logged_in_as(username) do
    visit "/card/remove/#{cardname.to_cardname.to_url_key}?card[confirm_destroy]=true"
  end
end

When /I wait a sec/ do
  sleep 1
end

Then /what/ do
  save_and_open_page
end

Then /debug/ do
  debugger
end

def fill_in_hidden_or_not(field_locator, options={})
  set_hidden_field(field_locator, :to=>options[:with])
rescue Exception => e
  fill_in(field_locator, options)
end

def create_card(username,cardtype,cardname,content="")
  logged_in_as(username) do
    visit "/card/new?card[name]=#{CGI.escape(cardname)}&type=#{cardtype}"
    #save_and_open_page
    yield if block_given?
    click_button("Submit")
    #save_and_open_page
    # Fixme - need better error handling here-- the following raise
    # at least keeps us from going on to the next step if the create bombs
    # but it doesn't report the reason for the failure.
#    raise "Creating #{cardname} failed (u=#{username}, t=#{cardtype}  )" unless Card[cardname]
    
  end
  #    rescue Exception => e
  #      raise %{ #{e.message}\n #{e.backtrace*"\n"} }
end

def logged_in_as(username)
  sameuser = (username == "I" or @current_user && @current_user.card.name == username)
  unless sameuser
    @saved_user = @current_user
    step "I log in as #{username}"
  end
  yield
  unless sameuser
    if @saved_user
      step "I log in as #{@saved_user.card.name}"
    else
      step "I log out"
    end
  end
end
                   

When /^In (.*) I follow "([^\"]*)"$/ do |section, link|
  within scope_of(section) do
    click_link link
  end
end

When /^In (.*) I click (.*)$/ do |section, link|
  within scope_of(section) do
    click_link link
  end
  
  
  # webrat.automate do
  #   within scope_of(section) do |scope|
  #     scope.click_link link
  #   end
  # end
  
#  webrat.simulate do                      
#    visit *params_for(control,section)
#  end                                             
end   
     
Then /the card (.*) should contain "([^\"]*)"$/ do |cardname, content|
  visit path_to("card #{cardname}")
  within scope_of("the main card content") do |scope|
    scope.should have_content(content)
  end
end

Then /the card (.*) should not contain "([^\"]*)"$/ do |cardname, content|
  visit path_to("card #{cardname}")
  within scope_of("the main card content") do |scope|
    scope.should_not have_content(content)
  end
end


Then /^In (.*) I should see "([^\"]*)"$/ do |section, text|
  within scope_of(section) do |scope|
    scope.should have_content(text)
  end
end


Then /^In (.*) I should not see "([^\"]*)"$/ do |section, text|
  within scope_of(section) do |scope|
    scope.should_not have_content(text)
  end
end

Then /^the "([^"]*)" field should contain "([^"]*)"$/ do |field, value|
  field_labeled(field).value.should =~ /#{value}/
end

Then /^"([^"]*)" should be selected for "([^"]*)"$/ do |value, field|
  field_labeled(field).element.search(".//option[@selected = 'selected']").inner_html.should =~ /#{value}/
end


## variants of standard steps to handle """ style quoted args
Then /^I should see$/ do |text|
  page.should have_content(text)
end

When /^I fill in "([^\"]*)" with$/ do |field, value|
  fill_in(field, :with => value) 
end

