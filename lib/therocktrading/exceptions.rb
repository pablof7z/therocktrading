module Therocktrading
  class CreateOrderException < RuntimeError; end
  class CancelOrderException < RuntimeError; end
  class WithdrawalException < RuntimeError; end
end
