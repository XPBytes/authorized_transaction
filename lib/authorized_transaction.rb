require "authorized_transaction/version"

require 'active_record'
require 'active_support/concern'
require 'active_support/core_ext/module/attribute_accessors'

module AuthorizedTransaction
  extend ActiveSupport::Concern
  class Error < StandardError; end

  mattr_accessor :authorize_proc, :implicit_action_proc, :implicit_action_key

  def self.configure
    yield self
  end

  class TransactionUnauthorized < RuntimeError
    attr_reader :action, :resource

    def initialize(action, resource)
      self.action = action
      self.resource = resource
      super format('You are not allowed to perform %<action>s on %<klazz>s', action: action, klazz: resource.class.name)
    end

    private

    attr_writer :action, :resource
  end

  included do
    ##
    # Wraps a block in a transaction after which the authorization check runs, using the controller action as default
    #   +action+ and the return value of the block as +resource+
    #
    # @param action [Symbol]
    # @yields a block to run actions and return a resource
    #
    # @throws TransactionUnauthorized
    #   when the +resource+ could not be +action+
    #
    # @example create a book first and check afterwards if it was allowed
    #
    #   class BookController < ApiController
    #     def create
    #       @book = authorized_transaction { CreateAndReturnBook.call(params) }
    #       render json: @book, status: :created
    #     end
    #   end
    #
    def authorized_transaction(action: implicit_action)
      ActiveRecord::Base.transaction do
        resource = yield
        authorize! action, resource
        resource
      end
    end

    def authorize!(action, resource)
      Array(resource).each do |r|
        next if authorized?(action, r)
        raise TransactionUnauthorized.new(action, r)
      end
    end
  end

  private

  def implicit_action
    if implicit_action_proc.respond_to?(:call)
      return implicit_action_proc(self)
    end

    params[implicit_action_key || :action]
  end

  def authorized?(action, resource)
    if authorize_proc.respond_to?(:call)
      return authorize_proc(action, resource, self)
    end

    can?(action, resource)
  end
end
