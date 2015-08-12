# -*- mode: ruby; coding: utf-8; -*-

require 'foodcritic'
require 'rubocop'
require 'berkshelf/thor'
# 'travis lint' can be called as a subprocess, but calling it from Ruby is
# preferable because it is cleaner and avoids loading the entire travis gem.
require 'travis/cli/lint'
require 'mixlib/shellout'
require 'artii'
require 'colorize'

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
    result = RuboCop::CLI.new.run %W(Berksfile Gemfile #{__FILE__} cookbooks
                                     config/osx/client.rb.sample
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
    lint = Travis::CLI::Lint.new
    lint.exit_code = true # Make lint exit with an exit code
    begin
      lint.run
    rescue SystemExit => e
      retval = e.status
    else
      # Travis::CLI::Lint.run will only exit if the file has errors
      retval = 0
    end
    exit retval if exit
    retval
  end

  desc 'all', 'Run all tests on the repository'
  def all
    # Pass false as an argument to prevent the task from exiting.
    sum = %w(rubocop foodcritic travis)
          .collect { |task| invoke('test:' + task, [false]) }
          .reduce(:+)
    if sum == 0
      print_msg 'PASS', :green
    else
      print_msg 'FAIL', :red
    end
    # Exit with the sum of the error codes.
    exit sum
  end

  private

  def print_msg(msg, color)
    artii = Artii::Base.new font: 'block'
    # artii adds two blank lines after the block text; we just want one.
    print artii.asciify(msg).lines[0..-2].join.colorize(color)
  end
end
