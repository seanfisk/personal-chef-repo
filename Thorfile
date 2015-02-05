# -*- mode: ruby; coding: utf-8; -*-

require 'foodcritic'
require 'rubocop'
require 'berkshelf/thor'
require 'strainer/thor'
require 'mixlib/shellout'

# Helper module for safely executing subprocesses.
module Subprocess
  def run_subprocess(*args)
    # Don't use `Bundler.with_clean_env' anymore, now that we're requiring the
    # chef gem. See `bundle help exec' for more info on using a 'clean'
    # environment.
    proc = Mixlib::ShellOut.new(args, live_stream: STDOUT)
    proc.run_command
    proc
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

# Tasks for testing cookbooks.
class Test < Thor
  desc 'strainer', 'Run strainer on all the cookbooks'
  def strainer(exit = true)
    # Strainer doesn't have a way to run on *all* the cookbooks, aside from
    # passing their names on the command-line. Fair enough...
    # http://stackoverflow.com/a/1899885
    invoke 'strainer:cli:test', Pathname.new('cookbooks').children
      .select(&:directory?)
      .collect { |p| p.basename.to_s }
  rescue SystemExit => e
    # Strainer calls exit(...), but we don't want it to exit when we're running
    # more tasks.
    exit e.status if exit
    e.status
  end

  desc 'other', 'Run rubocop on non-cookbook files'
  def other(exit = true)
    # Pass in a list of files/directories because we don't want the bin/
    # directory, other Foodcritic rules, or any of the cookbooks (tested by
    # Strainer) being checked.
    result = RuboCop::CLI.new.run \
      %W(Berksfile Gemfile #{ __FILE__ } .chef/knife.rb) +
      Dir.glob('config/{macosx,windows}/client.rb.sample')
    puts 'No rubocop errors on non-cookbook files' if result == 0
    exit result if exit
    result
  end

  desc 'all', 'Run all tests on the repository'
  def all
    # Exit with the sum of the error codes.
    exit invoke('test:other', [false]) + invoke('test:strainer', [false])
  end
end
