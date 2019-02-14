# AuthorizedTransaction

[![Build Status: master](https://travis-ci.com/XPBytes/authorized_transaction.svg)](https://travis-ci.com/XPBytes/authorized_transaction) 
[![Gem Version](https://badge.fury.io/rb/authorized_transaction.svg)](https://badge.fury.io/rb/authorized_transaction)
[![MIT license](http://img.shields.io/badge/license-MIT-brightgreen.svg)](http://opensource.org/licenses/MIT)

Authorize a certain block with cancan

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'authorized_transaction'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install authorized_transaction

## Usage

Wrap whatever you want to be authorized in an `authorized_transaction` block:

```ruby
require 'authorized_transaction'

class BookController < ApiController
  def create
    book = authorized_transaction { CreateAndReturnBook.call(params) }
    render json: book, status: :created
  end
end
```

Implicitly the current `action_name` will be used with `can? action, resource`. You can pass `action: ...` to the block
to set it explicitly:

```ruby
class Book::SignatureController < ApiController
  def create
    signature = authorized_transaction(action: :sign) { SignBook.call(params) }
    render json: signature, status: :created
  end
end
```

Authorization work on single resources, or enumerables:

```ruby
class Book::SignatureController < ApiController
  def show
    _, signature = authorized_transaction do 
        [FindBook.call(params), FindSignature.call(params)]
    end
    render json: signature, status: :created
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can
also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the
version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at [XPBytes/authorized_transaction](https://github.com/XPBytes/authorized_transaction).
