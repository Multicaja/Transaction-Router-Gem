# coding: utf-8

require "rails"
require "active_support/core_ext/class/attribute"
require "transaction_router/switch/class_loader"
require "transaction_router/switch/compiler"
require "transaction_router/switch/gateway"

module TransactionRouter
  class Switch
    include ClassLoader
    include Gateway
    include Compiler
    
    # conjunto de transacciones y las rutas por las que se irán
    class_attribute :route_set
    # settings generales del switch
    class_attribute :settings
    # caché de clases relacionadas con transacciones
    class_attribute :class_cache

    class << self

      def init(settings = {})
        merge_settings settings
        reset
      end

      def log
        self.settings[:logger]
      end

      def trx_blocks(name)
        raise "La transacción #{name} no existe" unless self.route_set[name]
        self.route_set[name][:blocks]
      end

      def trx_options(name)
        raise "La transacción #{name} no existe" unless self.route_set[name]
        self.route_set[name][:options]
      end

      def reset
        self.route_set = {}
        self.class_cache = {}
      end

      private

      def merge_settings(settings = {})
        default_settings = {}
        default_settings[:relative_file_path] = "test"
        default_settings[:root_path] = Rails.root.to_s
        # Se arroja cuando una transacción requiere un parámetro mínimo pero no lo recibe
        default_settings[:missing_arg_exception] = Application::ValidationError
        # Se arroja cuando una transacción es ejecutada con su método bang y el gateway no retorna 01
        default_settings[:bang_method_exception] = Application::ValidationError
        # Se arroja cuando una transacción debe retornar archivo, pero éste no existe
        default_settings[:on_file_not_found_exception] = Application::BaseWsError
        # Se arroja cuando una transación no puede encontrar su clase respectiva
        default_settings[:on_class_not_found_exception] = Application::ValidationError
        # Si se eliminan o no las llaves en string después de pasarlas a symbol
        default_settings[:force_result_translation] = false
        default_settings[:logger] = Rails.logger
        self.settings = default_settings.merge settings
      end

    end # ClassMethods

  end
end
