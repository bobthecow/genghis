# require 'spec_helper'

# describe 'Genghis', :type => :request do
#   it 'boots up' do
#     visit '/'
#     find('section#error').should_not be_visible
#     find('aside#alerts').text.should be_empty
#     page.should have_link 'Genghis'
#     page.should have_link 'Justin Hileman'
#   end

#   it 'starts at the server list' do
#     visit '/'
#     find('section#servers').should be_visible
#     find('section#databases').should_not be_visible
#     find('section#collections').should_not be_visible
#     find('section#documents').should_not be_visible
#     find('section#document').should_not be_visible
#   end

#   it 'has a magic button that shows and hides the "add server" form' do
#     visit '/'
#     within 'section#servers div.add-form' do
#       find('input.name').should_not be_visible
#       find('button.show').click
#       find('input.name').should be_visible
#       find('button.cancel').click
#       find('input.name').should_not be_visible
#     end
#   end
# end