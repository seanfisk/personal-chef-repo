require 'foodcritic'
require 'berkshelf/thor'

class Default < Thor
  desc 'test', 'Test all cookbooks'
  def test
    # Run cursory Chef knife tests on cookbooks
    check_system 'knife', 'cookbook', 'test', '--all'

    puts

    # Run foodcritic on cookbooks
    review = FoodCritic::Linter.new.check('cookbooks', {:fail_tags => ['any']})
    if review.warnings.any?
      puts review
    else
      puts 'No foodcritic errors'
    end
    exit !review.failed?
  end

  desc 'upload', 'Upload everything to the Chef server'
  def upload
    invoke 'berkshelf:upload'

    check_system 'knife', 'cookbook', 'upload', '--all'
  end

  private

  # TODO: This should probably be a standalone function or class method at least.
  def check_system(*args)
    system(*args)
    exit $?.exitstatus if $? != 0
  end
end
