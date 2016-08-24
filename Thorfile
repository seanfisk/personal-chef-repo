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
  def current_policy
    @current ||=
      begin
        # Load the current node's config. Stolen directly from the Chef source
        # code.
        require 'chef/application/client'
        # Load configuration from client.rb
        Chef::Application::Client.new.load_config_file
        policy = %i(group name).map do |key|
          [key, Chef::Config[:"policy_#{key}"]]
        end.to_h
      rescue KeyError
        $stderr.puts 'Unable to load config for current node'
        exit 1
      else
        policy_path =
          Pathname.new "policies/#{policy[:group]}/#{policy[:name]}.rb"
        unless policy_path.file?
          $stderr.puts "No policy found at '#{policy_path}'!"
          exit 1
        end
        policy[:path] = policy_path
        policy
      end
  end

  def all_policies
    Pathname
      .new('policies').children.select(&:directory?)
      .flat_map do |group_path|
        group_path
          .children
          .select do |name_path|
            name_path.extname == '.rb' && name_path.basename.to_s != 'base.rb'
          end
          .map do |name_path|
            { group: group_path.basename.to_s,
              name: name_path.basename.sub_ext('').to_s,
              path: name_path }
          end
      end
  end
end

# Tasks for interacting with the current Chef repository.
# NOTE: Naming this 'Chef' will cause conflicts!
class Repo < Thor
  include Subprocess
  include Policy

  desc 'push', 'Push everything to the Chef server'
  def push
    all_policies.each do |policy|
      run_subprocess %W(chef update #{policy[:path]})
      run_subprocess %W(chef push #{policy[:group]} #{policy[:path]})
    end
  end

  desc 'try', 'Run the policy for the current OS locally'
  def try
    policy = current_policy
    run_subprocess %W(chef update #{policy[:path]})
    Dir.mktmpdir do |export_dir|
      run_subprocess %W(chef export #{policy[:path]} #{export_dir})
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
    ) + (Pathname.new('config').children.map do |platform_dir|
      (platform_dir + 'client.rb.sample').to_s
    end).to_a
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
