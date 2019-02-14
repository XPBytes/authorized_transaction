require "test_helper"

class AuthorizedTransactionTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::AuthorizedTransaction::VERSION
  end
end
