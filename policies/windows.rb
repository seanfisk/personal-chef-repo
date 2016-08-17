name 'windows'

instance_eval(IO.read("#{File.dirname(__FILE__)}/base.rb"))

local_cookbooks %w(windows_setup)
