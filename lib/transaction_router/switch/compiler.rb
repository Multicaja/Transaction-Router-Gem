# coding: utf-8

require "transaction_router/switch/dsl"

module TransactionRouter
  class Switch
    module Compiler
      extend ActiveSupport::Concern

      module ClassMethods

        # Es el método que se ejecuta cuando se inicializa el Switch de transacciones. 
        # Este método crea en el Switch todos los métodos mencionados por el DSL
        def draw(&block)
          dsl = Dsl.new
          if block.arity >= 1
            raise "El DSL de transacciones debe ser escrito en un bloque que no recibe parámetros"
          end
          dsl.instance_exec &block
          self.route_set = dsl.route_set
          compile
        end

        private

        def compile
          self.route_set.each_key do |name, options|
            case options[:type]
            when :file
              class_eval <<-METODO_ARCHIVO, __FILE__, __LINE__ + 1
                def self.#{name}(params)
                  before_call "#{name}", params
                  result = archivo("#{name}", params)
                  after_call "#{name}", result, params
                  result
                end
              METODO_ARCHIVO
            when :class
              class_eval <<-METODO_SIMULADO, __FILE__, __LINE__ + 1
                def self.#{name}(params)
                  before_call "#{name}", params
                  result = simulado("#{name}", params)
                  after_call "#{name}", result, params
                  result
                end
              METODO_SIMULADO
            else # :ws
              class_eval <<-METODO_WS, __FILE__, __LINE__ + 1
                def self.#{name}(params)
                  before_call "#{name}", params
                  result = ws("#{name}", params)
                  after_call "#{name}", result, params
                  result
                end
              METODO_WS
            end
            class_eval <<-METODO_BANG, __FILE__, __LINE__ + 1
              def self.#{name}!(params)
                result = #{name}(params)
                raise(#{self.settings[:bang_method_exception]}, "La transacción no arrojó 01:'" + result["MENSAJE_RESPUESTA"] + "'") if result["CODIGO_RESPUESTA"] != "01"
                result
              end
            METODO_BANG
            end # foreach route
        end # compile method
      end # ClassMethods

    end # RouteBuilder 
  end
end