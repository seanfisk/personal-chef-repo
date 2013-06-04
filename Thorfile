require 'foodcritic'
require 'berkshelf/thor'

module SystemExec
  def check_system(*args)
    system(*args)
    exit $?.exitstatus if $? != 0
  end
end

class Knife < Thor
  include SystemExec

  desc 'test', 'Run cursory knife cookbook tests'
  def test
    check_system 'knife', 'cookbook', 'test', '--all'
  end

  desc 'upload', 'Upload all local cookbooks to the Chef server'
  def upload
    check_system 'knife', 'cookbook', 'upload', '--all'
  end
end

class Foodcritic < Thor
  desc 'test', 'Run foodcritic cookbook tests'
  def test
    review = FoodCritic::Linter.new.check('cookbooks', {
                                            :fail_tags => ['any'],
                                            :include_rules => ['foodcritic/etsy', 'foodcritic/customink'],
                                            # Don't worry about not having a CHANGELOG.md file for each cookbook.
                                            :tags => ['~CINK001']})
    if review.warnings.any?
      puts review
    else
      puts 'No foodcritic errors'
    end
    exit !review.failed?
  end
end

class Upload < Thor
  desc 'all', 'Upload everything to the Chef server'
  def all
    invoke 'berkshelf:upload'
    invoke 'knife:upload'
  end
end

class Test < Thor
  desc 'all', 'Run all tests on cookbooks'
  def all
    invoke 'knife:test'
    puts
    invoke 'foodcritic:test'
  end
end
