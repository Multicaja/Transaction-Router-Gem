# coding: utf-8
module TransactionRouter
  class Switch
    module ClassGateway
      extend ActiveSupport::Concern

      module ClassMethods

        # Responde la transacción con un método
        def simulado(transaction_name, params)
          klass = load_class transaction_name
          klass.simulate params
        end

      end # ClassMethods
    end
  end
end

