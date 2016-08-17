default_source :community
default_source :chef_repo, '..'

def local_cookbooks(cookbooks)
  run_list cookbooks
  cookbooks.each do |cookbook|
    cookbook cookbook
  end
end
