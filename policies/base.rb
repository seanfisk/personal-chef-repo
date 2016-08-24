def local_cookbooks(cookbooks)
  default_source :community
  default_source :chef_repo, File.dirname(__dir__)

  run_list cookbooks
  cookbooks.each do |cookbook|
    cookbook cookbook
  end
end
