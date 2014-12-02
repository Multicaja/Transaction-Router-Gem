# coding: utf-8
module TransactionRouter
  class Switch
    class WebserviceClient

      class_attribute :settings

      class << self

        def init(settings = {})
          default_settings = {}
          default_settings[:uri] = APP_CONFIG["ws"]["uri"]
          default_settings[:open_timeout] = APP_CONFIG["ws"]["open_timeout"]
          default_settings[:read_timeout] = APP_CONFIG["ws"]["read_timeout"]
          default_settings[:namespace] = "urn:multicaja_ws"
          default_settings[:multicaja_ws] = APP_CONFIG["ws"]["multicaja_ws"]
          default_settings[:on_timeout_exception] = Application::BaseWsError
          default_settings[:on_http_error_exception] = Application::BaseWsError
          default_settings[:on_soap_error_exception] = Application::BaseWsError
          default_settings[:on_empty_response_exception] = Application::BaseWsError
          default_settings[:logger] = Rails.logger
          self.settings = default_settings.merge settings
        end

        def log
          self.settings[:logger]
        end

        def call(tipo_tx, params, trx_options)
          #Item array creation
          item_array = []

          log.debug "TRXRTR REQUEST => #{params}"
    
          params.each do |name, value| 
            item_array << { :nombrecampo => name, :valorcampo => value }
          end
          
          #If the params array doesn't contain the name of the transaction, add it as an item. 
          #TODO: Remove this once all calls to this method are performed through gateway classes.
          unless params.has_key? "TIPO_TRX"
            item_array << { :nombrecampo => "TIPO_TRX", :valorcampo => tipo_tx }
          end
          
          body = { 
            :entrada => {
              "tipo-tx" => tipo_tx,
              :item => item_array
            }
          }
          
          op = trx_options
          uri = op[:uri] || self.settings[:uri]
          open_t = op[:open_timeout] || self.settings[:open_timeout]
          read_t = op[:read_timeout] || self.settings[:read_timeout]
          ns = op[:namespace] || self.settings[:namespace]
          multicaja_ws = op[:multicaja_ws] || self.settings[:multicaja_ws]

          # @client = Savon.client(wsdl: "./public/COW_2.wsdl", log: true, wsse_auth: ["usr_multicaja_01", "ht$Gb9c0aJU6"], wsse_timestamp: true, :ssl_verify_mode => :none, env_namespace: :soapenv)

          log.debug "URI => #{uri}"
          # proxy = Savon::Client.new(wsdl: uri, open_timeout: open_t, read_timeout: read_t, namespace: ns)
          proxy = Savon.client(wsdl: multicaja_ws, log: true, env_namespace: :soapenv, open_timeout: open_t, read_timeout: read_t)

          log.debug "proxy => #{proxy.inspect}"
          response = nil
          begin
            # proxy.body = body
            # response = client.call
            response = proxy.call(:webservice) do 
              # message("tipo-tx" => tipo_tx)
              message(body)
              # log.debug "message => #{message}"
            end
            # log.debug "TRXRTR RESPONSE: #{response}"
            # response = client.call(:entrada, message: {:tipo_tx => tipo_tx, item: => item_array})
            # response = proxy.webservice! do |soap|
            #   soap.namespace = ns
            #   soap.body = body
              # log.debug "\n \n =====REQUEST XML===#{tipo_tx}===>\n #{format_xml soap.to_xml} \n \n"
            #   soap
            # end
          rescue Timeout::Error => ext
            msg = <<EXT
Timeout al invocar al ws: #{ext.message}
  Params: #{body.to_s}
  Settings de timeout: 
    open: #{proxy.request.http.open_timeout}
    read: #{proxy.request.http.read_timeout}
EXT
            log.error "TRXRTR ERROR" + msg
            raise self.settings[:on_timeout_exception], msg
          rescue Savon::SOAPFault => exs
            msg = <<EXS
Error SOAP al invocar al ws: #{exs.message}
  Params: #{body.to_s}
EXS
            log.error "TRXRTR ERROR" + msg
            raise self.settings[:on_http_error_exception], msg
          rescue Savon::HTTPError => exh
            msg = <<EXH
Error HTTP al invocar al ws: #{exh.message}
  Params: #{body.to_s}
EXH
            log.error "TRXRTR ERROR" + msg
            raise self.settings[:on_soap_error_exception], msg
          end
          # se pasa la respuesta a un hash y se chequea que venga el arreglo de items
          result = response.to_hash
          if Rails.env = "development" then
            log.debug "\n \n =====RESPONSE XML ====#{tipo_tx}===>\n #{format_xml response.to_xml} \n \n"
          end
          log.debug "TRXRTR RESPONSE: #{result.to_s}"
          if response.nil? or not result.key?(:salida_estandar) or result[:salida_estandar].nil? or not result[:salida_estandar].key?(:item)
            msg = <<EXE
La respuesta del ws no es válida o no está completa: #{response.to_s}
EXE
            log.error "TRXRTR ERROR" + msg
            raise self.settings[:on_empty_response_exception], msg
          end
          # en vez de un arreglo de hashes individuales, se retorna un hash con pares :nombrecampo => :valorcampo
          asoc_arr = Hash.new
          asoc_arr[:request] = params
          result[:salida_estandar][:item].each do |par|
            asoc_arr[par[:nombrecampo]] = par[:valorcampo]
          end
          asoc_arr
        end
     
        def format_xml(xml)
          formatted = ""
          # Add Newlines
          xml = xml.gsub( /(>)(<)(\/*)/ ) { "#$1\n#$2#$3" }
          # Add Indents
          pad = 0
          xml.split( "\n" ).each do |node|
            # check various tag states
            indent = 0
            if node.match( /.+<\/\w[^>]*>$/ ) # open and closing on the same line
              indent = 0
            elsif node.match( /^<\/\w/ ) # closing tag
              pad -= 1 unless pad == 0
            elsif node.match( /^<\w[^>]*[^\/]>.*$/ ) # opening tag
              indent = 1
            else
              indent = 0
            end
            formatted << "\t" * pad + node + "\n"
            pad += indent
          end
          formatted
        end

      end # ClassMethods
    
    end # WebserviceClient
  end
end
