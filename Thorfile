# -*- mode: ruby; coding: utf-8; -*-

require 'foodcritic'
require 'rubocop'
require 'berkshelf/thor'
require 'mixlib/shellout'

# Helper module for safely executing subprocesses.
module Subprocess
  def run_subprocess(*args)
    # See `bundle help exec' for more info on using a 'clean' environment.
    Bundler.with_clean_env do
      proc = Mixlib::ShellOut.new(args, live_stream: STDOUT)
      proc.run_command
      proc
    end
  end
end

# Chef Knife-related tasks.
class Knife < Thor
  include Subprocess

  desc 'test', 'Run cursory knife cookbook tests'
  def test(exit = true)
    proc = run_subprocess 'knife', 'cookbook', 'test', '--all'
    exit proc.exitstatus if exit
    proc.exitstatus
  end

  desc 'upload', 'Upload all local cookbooks to the Chef server'
  def upload
    proc = run_subprocess 'knife', 'cookbook', 'upload', '--all'
    proc.error!
  end
end

# Foodcritic-related tasks.
class Foodcritic < Thor
  desc 'test', 'Run foodcritic cookbook tests'
  def test(exit = true)
    review = lint

    if review.warnings.any?
      puts review
      retval = 1
    else
      puts 'No foodcritic errors'
      retval = 0
    end
    exit retval if exit
    retval
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
  def check(exit = true)
    # Pass in a list of files/directories because we don't want the bin/
    # directory, other Foodcritic rules, etc., being checked.
    result = Rubocop::CLI.new.run %W(Berksfile Gemfile #{ __FILE__ } cookbooks
                                     config/macosx/client.rb.sample
                                     config/windows/client.rb.sample
                                     .chef/knife.rb)
    puts 'No rubocop errors' if result == 0
    exit result if exit
    result
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
    # Pass false as an argument to prevent the task from exiting.
    knife_result = invoke 'knife:test', [false]
    puts
    fc_result = invoke 'foodcritic:test', [false]
    style_result = invoke 'style:check', [false]

    # Exit with the sum of the test categories.
    exit knife_result + fc_result + style_result
  end

  desc 'no-knife', 'Run all tests besides Knife tests'
  def no_knife
    fc_result = invoke 'foodcritic:test', [false]
    style_result = invoke 'style:check', [false]

    # Exit with the sum of the test categories.
    exit fc_result + style_result
  end
end
