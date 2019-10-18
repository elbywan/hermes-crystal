require "./bindings"

module Mappings
    include Bindings

    class StringArray
        def initialize(@array = [] of String)
        end

        def to_unsafe
            LibHermes::CStringArray.new(
                data: @array.map { |elt| elt.to_unsafe },
                size: @array.size
            )
        end
    end

    class MqttOptions
        def initialize(
            @broker_address = "",
            @username = "",
            @password = "",
            @tls_hostname = "",
            @tls_ca_file = [] of String,
            @tls_ca_path = [] of String,
            @tls_client_key = "",
            @tls_client_cert = "",
            @tls_disable_root_store : UInt8 = 0
        )
        end

        def to_unsafe
            c_options = LibHermes::CMqttOptions.new

            c_options.broker_address = @broker_address unless @broker_address.empty?
            c_options.username = @username unless @username.empty?
            c_options.password = @password unless @password.empty?
            c_options.tls_hostname = @tls_hostname unless @tls_hostname.empty?
            tls_ca_file = StringArray.new(@tls_ca_file).to_unsafe
            c_options.tls_ca_file = pointerof(tls_ca_file)
            tls_ca_path = StringArray.new(@tls_ca_path).to_unsafe
            c_options.tls_ca_path = pointerof(tls_ca_path)
            c_options.tls_client_key = @tls_client_key unless @tls_client_key.empty?
            c_options.tls_client_cert = @tls_client_cert unless @tls_client_cert.empty?
            c_options.tls_disable_root_store = @tls_disable_root_store

            c_options
        end
    end
end