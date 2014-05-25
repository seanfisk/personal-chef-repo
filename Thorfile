# -*- mode: ruby; coding: utf-8; -*-

require 'English' # for $CHILD_STATUS
require 'foodcritic'
require 'rubocop'
require 'berkshelf/thor'

module SystemExec
  def check_system(*args)
    # See `bundle help exec' for more info on using a 'clean' environment.
    Bundler.with_clean_env do
      system(*args)
      exit $CHILD_STATUS.exitstatus if $CHILD_STATUS != 0
    end
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
    review = FoodCritic::Linter.new.check({
      cookbook_paths: 'cookbooks',
      fail_tags: ['any'],
      include_rules: ['foodcritic/etsy', 'foodcritic/customink'],
      # Don't worry about having a CHANGELOG.md file for each cookbook.
      tags: ['~CINK001'] })

    if review.warnings.any?
      puts review
      exit !review.failed?
    else
      puts 'No foodcritic errors'
    end
  end
end

# Make sure you don't re-define the Rubocop module here. That's why
# it's named Style.
class Style < Thor
  desc 'check', 'Run rubocop on all Ruby files'
  def check
    result = Rubocop::CLI.new.run %W{
Berksfile Gemfile #{ __FILE__ } cookbooks }
    if result == 0
      puts 'No rubocop errors'
    else
      exit result
    end
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
    invoke 'style:check'
  end
end
