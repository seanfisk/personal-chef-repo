# -*- mode: ruby; coding: utf-8; -*-

require 'pathname'
require 'foodcritic'
require 'rubocop'
# 'travis lint' can be called as a subprocess, but calling it from Ruby is
# preferable because it is cleaner and avoids loading the entire travis gem.
require 'travis/cli/lint'
require 'mixlib/shellout'
require 'artii'
require 'colorize'
require 'ohai'

# Helper module for safely executing subprocesses.
module Subprocess
  # Mixlib::ShellOut doesn't support arrays on Windows... Ugh.
  def run_subprocess(cmd, **opts)
    # See `bundle help exec' for more info on using a 'clean' environment.
    Bundler.with_clean_env do
      proc = Mixlib::ShellOut.new(cmd, live_stream: STDOUT, **opts)
      proc.run_command
      proc
    end
  end
end

# Helper module for determining the current operating system.
module Platform
  def current_platform
    system = Ohai::System.new
    system.all_plugins('platform')
    system['platform']
  end
end

# Tasks for uploading cookbooks to the Chef server.
class Chef < Thor
  include Subprocess
  include Platform

  desc 'push', 'Push everything to the Chef server'
  def push
    Pathname.glob('policies/*.rb').each do |policyfile|
      run_subprocess "chef update #{policyfile}"
      run_subprocess(
        "chef push #{policyfile.basename.sub_ext('')} #{policyfile}"
      )
    end
  end

  desc 'try', 'Run the policy for the current OS locally'
  def try
    platform = current_platform
    policy_platform = {
      'mac_os_x' => 'osx',
      'windows' => 'windows'
    }[platform]
    unless policy_platform
      puts "Platform not supported: #{platform}"
      exit 1
    end
    policyfile = "policies/#{policy_platform}.rb"
    run_subprocess "chef update #{policyfile}"
    Dir.mktmpdir do |export_dir|
      run_subprocess "chef export #{policyfile} #{export_dir}"
      # We need to run as a subprocess (not exec) in order to delete the temp
      # directory afterwards.

      # Obnoxiously chef-client *requires* PWD to be set to the correct value,
      # otherwise the correct repo isn't found.

      # The last two options make the client behave as if it was outputting
      # directory to a TTY.
      run_subprocess 'chef-client --local-mode --format doc --log_level warn',
                     cwd: export_dir,
                     env: { 'PWD' => export_dir }
    end
  end
end

# Tasks for testing.
class Test < Thor
  include Subprocess

  desc 'rubocop', 'Run rubocop on all Ruby files'
  def rubocop(exit = true)
    # Pass in a list of files/directories because we don't want the bin/
    # directory, other Foodcritic rules, etc., being checked.
    result = RuboCop::CLI.new.run %W(
      Gemfile #{__FILE__} cookbooks policies config/osx/client.rb.sample
      config/windows/client.rb.sample .chef/knife.rb
    )
    puts 'No rubocop errors'.colorize(:green) if result == 0
    exit result if exit
    result
  end

  desc 'foodcritic', 'Run foodcritic cookbook tests'
  def foodcritic(exit = true)
    review = FoodCritic::Linter.new.check(
      cookbook_paths: 'cookbooks',
      fail_tags: ['any'],
      include_rules: ['foodcritic/etsy', 'foodcritic/customink'],
      tags: [
        # Don't worry about having a CHANGELOG.md file for each cookbook.
        '~CINK001',
        # XXX This is disabled due to binary data (\x00) in our windows_setup
        # cookbook incorrectly being flagged as an unnecessary use of double
        # quotes. We should fix this upstream.
        '~CINK002'
      ]
    )

    if review.warnings.any?
      puts review
      retval = 1
    else
      puts 'No foodcritic errors'.colorize(:green)
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
