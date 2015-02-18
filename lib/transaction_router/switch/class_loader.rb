# coding: utf-8
module TransactionRouter
  class Switch
    module ClassLoader
      extend ActiveSupport::Concern

      module ClassMethods

        # Retorna la instancia asociada a la transacción, o levanta una excepción si no existe
        def instance_class!(transaction_name)
          instance_class transaction_name, true
        end

        # Retorna la instancia asociada a la transacción, o nil si no existe
        def instance_class(transaction_name, force = false)
          unless self.class_cache.key? transaction_name
            # La clase no ha sido cargada, la cargamos y guardamos en el caché
            klass = get_class transaction_name, force
            # Switch.log.debug "Switch->[#{transaction_name}]: La clase #{klass} no se encuentra en el caché. Instanciando..."
            if klass
              simulator = klass.new
              self.class_cache[transaction_name] = simulator
            end
          end
          # La clase ya está cargada, la retornamos del caché
          self.class_cache[transaction_name]
        end

        # Obtiene la constante que contiene la clase de la transacción
        def get_class(transaction_name, force)
          op = trx_options transaction_name
          if op[:klass]
            klass = op[:klass]
          else
            klass_name = "#{transaction_name.to_s.camelize}Transaction"
            if class_exists? klass_name
              klass = const_get klass_name
            elsif force
              # Switch.log.error "Switch->[#{transaction_name}]: Ups! No se encontró la clase #{klass_name}..."
              raise self.settings[:on_class_not_found_exception], "La transacción #{transaction_name} no se pudo simular porque no existe la clase #{klass_name}" 
            else
              # Switch.log.debug "Switch->[#{transaction_name}]: La clase #{klass_name} no existe."
              return nil
            end
          end
        end

        def class_exists?(class_name)
          begin
            klass = Module.const_get(class_name)
            return klass.is_a?(Class)
          rescue NameError
            return false
          end
        end
        
      end # ClassMethods
    end
  end
end

