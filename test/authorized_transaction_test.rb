require 'test_helper'

class AuthorizedTransactionTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::AuthorizedTransaction::VERSION
  end

  class MyResource
    def initialize(data)
      self.data = data
    end

    attr_reader :data

    private
    attr_writer :data
  end

  class BaseController
    def initialize
      @params = { action: :implicit_action, authorized_action: :galaxy }
    end

    def params
      @params
    end

    def can?(action, resource)
      return resource.is_a?(MyResource) if action == :implicit_action
      resource.data == 42
    end
  end

  class FakeController < BaseController
    include AuthorizedTransaction

    def action(resource)
      authorized_transaction { resource }
    end

    def explicit_action(resource, action:)
      authorized_transaction(action: action) { resource }
    end
  end

  def setup
    @controller = FakeController.new
    @transaction_state = transaction_state = { started: false, committed: false }

    AuthorizedTransaction.configure do
      # Mimic ActiveRecord transaction
      self.transaction_proc = proc do |&block|
        transaction_state[:started] = true
        result = block.call
        transaction_state[:committed] = true

        result
      end
    end
  end

  def teardown
    AuthorizedTransaction.configure do
      self.authorize_proc = nil
      self.implicit_action_proc = nil
      self.implicit_action_key = nil
      self.transaction_proc = nil
    end
  end

  def test_it_authorizes
    result = @controller.action(MyResource.new(1))
    assert_equal result.data, 1, 'expected resource to be passed through'
    assert_equal @transaction_state[:committed], true, 'expected transaction to be committed'
  end

  def test_it_authorizes_explicitly
    result = @controller.explicit_action(MyResource.new(42), action: :foo)
    assert_equal result.data, 42, 'expected resource to be passed through'
    assert_equal @transaction_state[:committed], true, 'expected transaction to be committed'
  end

  def test_it_raises_on_unauthorized
    assert_raises AuthorizedTransaction::TransactionUnauthorized do
      @controller.action('Not MyResource')
    end

    assert_equal @transaction_state[:started], true, 'expected transaction to have started'
    assert_equal @transaction_state[:committed], false, 'expected transaction not to committed'
  end

  def test_it_authorizes_with_custom_can
    AuthorizedTransaction.authorize_proc = proc do |action, resource|
      action == resource.data
    end

    @controller.explicit_action(MyResource.new(:foo), action: :foo)
    assert_equal @transaction_state[:started], true, 'expected transaction to have started'
    assert_equal @transaction_state[:committed], true, 'expected transaction to be committed'
  end

  def test_it_raises_with_custom_can
    AuthorizedTransaction.authorize_proc = proc do |action, resource|
      action == resource.data
    end

    assert_raises AuthorizedTransaction::TransactionUnauthorized do
      @controller.explicit_action(MyResource.new(:bar), action: :foo)
    end

    assert_equal @transaction_state[:started], true, 'expected transaction to have started'
    assert_equal @transaction_state[:committed], false, 'expected transaction not to committed'
  end

  def test_it_can_change_implicit_action_key
    AuthorizedTransaction.authorize_proc = proc { |action| action == :galaxy }
    AuthorizedTransaction.implicit_action_key = :authorized_action

    @controller.action('NotMyResource')
    assert_equal @transaction_state[:started], true, 'expected transaction to have started'
    assert_equal @transaction_state[:committed], true, 'expected transaction to be committed'
  end
end
