# -*- mode: ruby; coding: utf-8; -*-

require 'pathname'
require 'English'
require 'foodcritic'
require 'rubocop'
# 'travis lint' can be called as a subprocess, but calling it from Ruby is
# preferable because it is cleaner and avoids loading the entire travis gem.
require 'travis/cli/lint'
require 'artii'
require 'rainbow'
require 'ohai'

# Helper module for safely executing subprocesses.
module Subprocess
  # Mixlib::ShellOut doesn't support arrays on Windows... Ugh.
  def run_subprocess(cmd, **opts)
    # See `bundle help exec' for more info on using a 'clean' environment.
    Bundler.with_clean_env do
      env = opts.fetch(:env, {})
      opts.delete(:env)
      # Force Ruby to not use a shell by using the argv[0]-setting syntax
      puts Rainbow('==> ').bright.blue + Rainbow(cmd.inspect).bright
      unless system(env, [cmd[0], cmd[0]], *cmd[1..-1], **opts)
        status = $CHILD_STATUS.exitstatus
        $stderr.puts 'Command failed with non-zero '\
                     "exit code #{status}: #{cmd.inspect}"
        exit status
      end
    end
  end
end

# Helper module for policyfiles.
module Policy
  def current_policyfile
    ohai = Ohai::System.new
    ohai.all_plugins('platform')
    platform = CHEF_TO_PERSONAL[ohai['platform']]
    unless platform
      puts "Platform not supported: #{platform}"
      exit 1
    end
    policyfile_path(platform)
  end

  def all_policyfiles
    CHEF_TO_PERSONAL.values.map { |platform| policyfile_path(platform) }
  end

  def supported_platforms
    CHEF_TO_PERSONAL.values
  end

  def policyfile_path(platform)
    "policies/#{platform}.rb"
  end

  CHEF_TO_PERSONAL = {
    'mac_os_x' => 'macos',
    'windows' => 'windows'
  }.freeze
end

# Tasks for uploading cookbooks to the Chef server.
class Chef < Thor
  include Subprocess
  include Policy

  desc 'push', 'Push everything to the Chef server'
  def push
    supported_platforms.each do |platform|
      policyfile = policyfile_path(platform)
      run_subprocess %W(chef update #{policyfile})
      run_subprocess(
        %W(chef push #{platform} #{policyfile})
      )
    end
  end

  desc 'try', 'Run the policy for the current OS locally'
  def try
    policyfile = current_policyfile
    run_subprocess %W(chef update #{policyfile})
    Dir.mktmpdir do |export_dir|
      run_subprocess %W(chef export #{policyfile} #{export_dir})
      # We need to run as a subprocess (not exec) in order to delete the temp
      # directory afterwards.

      # Obnoxiously chef-client *requires* PWD to be set to the correct value,
      # otherwise the correct repo isn't found.

      # The last two options make the client behave as if it was outputting
      # directory to a TTY.
      run_subprocess %w(chef-client --local-mode --format doc --log_level warn),
                     chdir: export_dir,
                     env: { 'PWD' => export_dir }
    end
  end
end

# Tasks for testing.
class Test < Thor
  include Policy

  desc 'rubocop', 'Run rubocop on all Ruby files'
  def rubocop(exit = true)
    # Pass in a list of files/directories because we don't want the bin/
    # directory, other Foodcritic rules, etc., being checked.
    result = RuboCop::CLI.new.run %W(
      Gemfile #{__FILE__} cookbooks policies .chef/knife.rb
    ) + (supported_platforms.map do |platform|
      "config/#{platform}/client.rb.sample"
    end)
    puts Rainbow('No rubocop errors').green if result == 0
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
      puts Rainbow('No foodcritic errors').green
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
    message, color = sum == 0 ? ['PASS', :green] : ['FAIL', :red]
    artii = Artii::Base.new font: 'block'
    # artii adds two blank lines after the block text; we just want one.
    print Rainbow(artii.asciify(message).lines[0..-2].join).color(color)
  end
end
