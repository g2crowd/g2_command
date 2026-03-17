# Command

This gem is an implementation of the command pattern, heavily inspired and mirroring the implementation by [active_interaction](https://github.com/AaronLasseigne/active_interaction) with the major difference being using the [dry-rb](https://dry-rb.org/) libraries.

Commands encapsulate a single unit of business logic with typed inputs, validations, and monadic (Success/Failure) results. They keep your controllers, jobs, and models thin by giving each operation a dedicated, testable home.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'g2_command'
```

And then execute:

    $ bundle install

## Usage

### Defining a Command

Include `Command` in a class, declare inputs with `option`, and implement `execute`:

```ruby
module Users
  class ResetPassword
    include Command

    option :user, type: Types.Instance(User)
    option :new_password, type: Types::String

    def execute
      user.update!(password: new_password)
      user
    end
  end
end
```

The constructor is private — you never call `.new` directly.

### Running a Command

#### `.run` — Returns a `Dry::Monads::Result` (Success or Failure)

```ruby
outcome = Users::ResetPassword.run(user: current_user, new_password: "s3cure!")

if outcome.success?
  redirect_to root_path
else
  @errors = outcome.failure.errors.full_messages
  render :edit
end
```

On success, `outcome.value!` returns whatever `execute` returned.

On failure, `outcome.failure` returns a `Command::Failure` with `.errors` (an `ActiveModel::Errors` instance) and `.result` (whatever `execute` returned before the errors were detected).

#### `.run!` — Returns the value directly or raises

```ruby
user = Users::ResetPassword.run!(user: current_user, new_password: "s3cure!")
```

If the command fails, `.run!` raises `Dry::Monads::UnwrapError`. Use this when failure is unexpected and should be treated as an exception (jobs, other commands, etc.).

### Declaring Inputs with `option`

Inputs are declared using `option` from [dry-initializer](https://dry-rb.org/gems/dry-initializer). All inputs are keyword arguments.

#### Required inputs

```ruby
option :user, type: Types.Instance(User)
option :amount, type: Types::Integer
```

Missing required inputs raise `KeyError` at invocation time.

#### Optional inputs with defaults

```ruby
option :limit, type: Types::Integer, default: proc { 25 }
option :notify, type: Types::Bool, default: proc { true }
option :logger, optional: true
```

`default:` must be a `proc` (not a bare value) because dry-initializer evaluates it at instantiation time. The proc runs in the context of the instance, so it can reference other options:

```ruby
option :product, type: Types.Instance(Product)
option :access, type: Types::String, default: proc { product.default_access_level }
```

### Type System

Commands use [dry-types](https://dry-rb.org/gems/dry-types) via the `Types` module. Common types:

| Type                           | Description                                    |
| ------------------------------ | ---------------------------------------------- |
| `Types::String`                | Must be a String                               |
| `Types::Integer`               | Must be an Integer                             |
| `Types::Bool`                  | Must be `true` or `false`                      |
| `Types::Time`                  | Must be a Time                                 |
| `Types::Coercible::Integer`    | Coerces input to Integer (e.g., `"42"` → `42`) |
| `Types::Coercible::String`     | Coerces input to String                        |
| `Types.Instance(User)`         | Must be an instance of `User`                  |
| `Types::String.enum('a', 'b')` | Must be one of the listed values               |
| `Types.Interface(:call)`       | Must respond to `:call` (duck typing)          |
| `Types::Array`                 | Must be an Array                               |
| `Types::String.optional`       | Allows `nil` as a value                        |

Omitting `type:` means no type checking is performed on that input.

### Validations

Commands include `ActiveModel::Validations`, so you can use any standard Rails validation:

```ruby
module Accounts
  class Transfer
    include Command

    option :from_account, type: Types.Instance(Account)
    option :to_account, type: Types.Instance(Account)
    option :amount, type: Types::Integer

    validates :amount, numericality: { greater_than: 0 }
    validate :accounts_are_different

    def execute
      from_account.withdraw!(amount)
      to_account.deposit!(amount)
    end

    private

    def accounts_are_different
      errors.add(:to_account, "must be different from source") if from_account == to_account
    end
  end
end
```

Validations run **before** `execute`. If any fail, `execute` is never called and `.run` returns a `Failure`.

You can also add errors **during** `execute`:

```ruby
def execute
  result = external_api.charge(amount)

  if result.declined?
    errors.add(:base, "Payment declined: #{result.reason}")
    return
  end

  result.transaction
end
```

If `errors` is non-empty after `execute`, the command returns a `Failure` even though `execute` ran.

### Composing Commands

Use `compose` inside `execute` to call another command. If the composed command fails, its errors are merged into the parent and execution halts immediately via `Command::Interrupt`:

```ruby
module OrganizationAdmin
  class FindOrCreateCompetitors
    include Command

    option :scope, type: Types::String.enum('executive_summary', 'full'),
                   default: -> { 'executive_summary' }
    option :product, type: Types.Instance(Product)
    option :user, type: Types.Instance(User)

    def execute
      config || build_config
    end

    private

    def config
      user.competitor_configurations
          .select { |c| c.product == product && c.scope == scope }
          .first
    end

    def build_config
      CompetitorConfiguration.create!(product:, user:, competitors:, scope:)
    end

    def competitors
      compose(VendorAdmin::Competitors::FindTopCompetitors,
              product:, max: CompetitorConfiguration::MAX_COMPETITORS)
    end
  end
end
```

`compose` returns the composed command's return value on success. On failure, the parent command's errors are populated and a `Command::Interrupt` is raised (caught internally by `run`), so the parent also fails with the child's errors.

### Accessing Inputs

Use `inputs` to get a hash of all declared option values. This is useful when forwarding to a composed command:

```ruby
def execute
  compose(OtherCommand, inputs)
end
```

### Input Middleware

The gem automatically processes inputs through middleware before passing them to the initializer:

1. **RailsParams** — If given `ActionController::Parameters`, converts to a plain hash via `to_unsafe_h`
2. **Symbolizer** — Symbolizes all hash keys

This means you can pass `params` directly from a controller:

```ruby
MyCommand.run(params)
```

### Complete Example

```ruby
module Reviews
  class Submit
    include Command

    option :user, type: Types.Instance(User)
    option :product, type: Types.Instance(Product)
    option :rating, type: Types::Coercible::Integer
    option :body, type: Types::String
    option :notify_vendor, type: Types::Bool, default: proc { true }

    validates :rating, inclusion: { in: 1..5 }
    validates :body, length: { minimum: 50 }
    validate :user_has_not_already_reviewed

    def execute
      review = product.reviews.create!(
        user: user,
        rating: rating,
        body: body
      )

      compose(Notifications::SendReviewAlert, review:) if notify_vendor

      review
    end

    private

    def user_has_not_already_reviewed
      return unless product.reviews.exists?(user: user)

      errors.add(:user, "has already reviewed this product")
    end
  end
end
```

**Calling from a controller:**

```ruby
def create
  outcome = Reviews::Submit.run(
    user: current_user,
    product: @product,
    rating: params[:rating],
    body: params[:body]
  )

  if outcome.success?
    redirect_to outcome.value!, notice: "Review submitted!"
  else
    @errors = outcome.failure.errors
    render :new
  end
end
```

**Calling from a job or another command (where failure is unexpected):**

```ruby
review = Reviews::Submit.run!(user: user, product: product, rating: 5, body: long_text)
```

## API Reference

### Class Methods

| Method            | Returns                                          | Description                                                                          |
| ----------------- | ------------------------------------------------ | ------------------------------------------------------------------------------------ |
| `.run(**inputs)`  | `Dry::Monads::Success` or `Dry::Monads::Failure` | Validates and executes the command. Returns a monadic result.                        |
| `.run!(**inputs)` | The return value of `execute`                    | Same as `.run` but unwraps the result. Raises `Dry::Monads::UnwrapError` on failure. |

### Instance Methods (available inside `execute`)

| Method                            | Returns                                              | Description                                                      |
| --------------------------------- | ---------------------------------------------------- | ---------------------------------------------------------------- |
| `errors`                          | `ActiveModel::Errors`                                | Add errors during execution via `errors.add(:field, "message")`. |
| `compose(CommandClass, **inputs)` | The return value of the composed command's `execute` | Runs another command. Merges errors and halts on failure.        |
| `inputs`                          | `Hash`                                               | Returns a hash of all declared option values.                    |

### Result Objects

**On Success** (`outcome.success?` is `true`):

```ruby
outcome.value!  # => whatever execute returned
```

**On Failure** (`outcome.failure?` is `true`):

```ruby
outcome.failure.errors           # => ActiveModel::Errors
outcome.failure.errors.full_messages  # => ["Age must be less than 20"]
outcome.failure.result           # => whatever execute returned (may be nil)
```

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

These are useful for stubbing command calls in tests:

```ruby
allow(Users::ResetPassword).to receive(:run).and_return(create_outcome(value: user))
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/g2crowd/g2_command. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/g2crowd/g2_command/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Command project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/g2crowd/g2_command/blob/main/CODE_OF_CONDUCT.md).
