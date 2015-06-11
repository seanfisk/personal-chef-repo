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

  desc 'upload', 'Upload all local cookbooks to the Chef server'
  def upload
    proc = run_subprocess 'knife', 'cookbook', 'upload', '--all'
    proc.error!
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

# Tasks for testing.
class Test < Thor
  include Subprocess

  desc 'rubocop', 'Run rubocop on all Ruby files'
  def rubocop(exit = true)
    # Pass in a list of files/directories because we don't want the bin/
    # directory, other Foodcritic rules, etc., being checked.
    result = RuboCop::CLI.new.run %W(Berksfile Gemfile #{ __FILE__ } cookbooks
                                     config/macosx/client.rb.sample
                                     config/windows/client.rb.sample
                                     .chef/knife.rb)
    puts 'No rubocop errors' if result == 0
    exit result if exit
    result
  end

  desc 'foodcritic', 'Run foodcritic cookbook tests'
  def foodcritic(exit = true)
    review = FoodCritic::Linter.new.check(
      cookbook_paths: 'cookbooks',
      fail_tags: ['any'],
      include_rules: ['foodcritic/etsy', 'foodcritic/customink'],
      # Don't worry about having a CHANGELOG.md file for each cookbook.
      tags: ['~CINK001']
    )

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

  desc 'travis', "Run 'travis lint' on '.travis.yml'"
  def travis(exit = true)
    puts 'Linting travis file'
    proc = run_subprocess 'travis', 'lint', '--exit-code'
    exit proc.exitstatus if exit
    proc.exitstatus
  end

  desc 'all', 'Run all tests on the repository'
  def all
    # Exit with the sum of the error codes. Pass false as an argument to
    # prevent the task from exiting.
    exit %w(rubocop foodcritic travis)
      .collect { |task| invoke('test:' + task, [false]) }
      .reduce(:+)
  end
end
