# -*- mode: ruby; coding: utf-8; -*-

require 'foodcritic'
require 'rubocop'
require 'berkshelf/thor'
require 'mixlib/shellout'

# Helper module for safely executing subprocesses.
module SystemExec
  def check_system(*args)
    # See `bundle help exec' for more info on using a 'clean' environment.
    Bundler.with_clean_env do
      proc = Mixlib::ShellOut.new(args)
      proc.run_command
      puts proc.stdout
      proc.error!
    end
  end
end

# Chef Knife-related tasks.
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

# Foodcritic-related tasks.
class Foodcritic < Thor
  desc 'test', 'Run foodcritic cookbook tests'
  def test
    review = lint

    if review.warnings.any?
      puts review
      exit !review.failed?
    else
      puts 'No foodcritic errors'
    end
  end

  private

  def lint
    FoodCritic::Linter.new.check(
      cookbook_paths: 'cookbooks',
      fail_tags: ['any'],
      include_rules: ['foodcritic/etsy', 'foodcritic/customink'],
      # Don't worry about having a CHANGELOG.md file for each cookbook.
      tags: ['~CINK001']
    )
  end
end

# Rubocop-related tasks.
class Style < Thor
  # Make sure you don't re-define the Rubocop module here. That's why
  # it's named Style.
  desc 'check', 'Run rubocop on all Ruby files'
  def check
    # Pass in a list of files/directories because we don't want the bin/
    # directory, other Foodcritic rules, etc., being checked.
    result = Rubocop::CLI.new.run %W(Berksfile Gemfile #{ __FILE__ } cookbooks)
    exit result if result != 0
    puts 'No rubocop errors'
  end
end

# Tasks for uploading cookbooks to the Chef server.
class Upload < Thor
  desc 'all', 'Upload everything to the Chef server'
  def all
    invoke 'berkshelf:upload'
    invoke 'knife:upload'
  end
end

# Tasks for testing cookbooks.
class Test < Thor
  desc 'all', 'Run all tests on cookbooks'
  def all
    invoke 'knife:test'
    puts
    invoke 'foodcritic:test'
    invoke 'style:check'
  end
end
