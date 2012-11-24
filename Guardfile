# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'rake', :task => 'build' do
  watch(%r{^src/.*\.(rb|php|js|less|erb|mustache)$})
end

guard 'rspec' do
  watch(%r{^spec/.+_spec\.rb$})
  watch('spec/spec_helper.rb')   { 'spec' }
  watch(%r{^genghis\.(php|rb)$}) { 'spec' }
end

