source 'https://rubygems.org'

group :development do
  gem 'chef'
end

group :test do
  gem 'thor'
  gem 'foodcritic'
  gem 'rubocop'
  # Berkshelf has to be in here because it is required in the Thorfile
  # which is run for the tests. It's not a great solution, but it
  # works.
  gem 'berkshelf'
end
