# Command

This gem is an implementation of the command pattern, heavily inspired and mirroring the implementation by [active_interaction](https://github.com/AaronLasseigne/active_interaction) with the major difference being using the [dry-rb](https://dry-rb.org/) libraries.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'g2_command'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install g2_command

## Usage

TODO: Write usage instructions here

## RSpec Helper

In `spec_helper.rb`:

```ruby
require 'command/test_helper'

RSpec.configure do |config|
  config.include Command::TestHelper
end
```

Create a Success outcome object:

```ruby
  let(:outcome) { create_outcome(value: 'Return value') }
```

Create a Failure outcome object:

```ruby
  let(:outcome) { create_outcome(errors: { user: 'is invalid' }) }
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/g2crowd/g2_command. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/g2_command/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Command project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/g2crowd/g2_command/blob/main/CODE_OF_CONDUCT.md).
