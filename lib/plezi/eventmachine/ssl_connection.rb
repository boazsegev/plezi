# encoding: UTF-8



module Plezi

	module EventMachine

		# represents an SSL connection
		class SSLConnection < Connection
			#the SSL socket
			attr_reader :ssl_socket

			def initialize socket, params
				if params[:ssl_client]
					context = OpenSSL::SSL::SSLContext.new
					context.set_params verify_mode: OpenSSL::SSL::VERIFY_NONE # OpenSSL::SSL::VERIFY_PEER #OpenSSL::SSL::VERIFY_NONE
					@ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, context)
					@ssl_socket.sync_close = true
					@ssl_socket.connect
				elsif params[:ssl] || params[:ssl_key] || params[:ssl_cert]
					params[:ssl_cert], params[:ssl_key] = SSLConnection.self_cert unless params[:ssl_key] && params[:ssl_cert]
					context = OpenSSL::SSL::SSLContext.new
					context.set_params verify_mode: OpenSSL::SSL::VERIFY_NONE # OpenSSL::SSL::VERIFY_PEER #OpenSSL::SSL::VERIFY_NONE
					# context.options DoNotReverseLookup: true
					context.cert, context.key = params[:ssl_cert], params[:ssl_key]
					context.cert_store = OpenSSL::X509::Store.new
					context.cert_store.set_default_paths
					@ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, context)
					@ssl_socket.sync_close = true
					@ssl_socket.accept
				end
				raise "Not an SSL connection or SSL Socket creation failed" unless @ssl_socket
				super
			end


			# returns an IO-like object used for reading/writing (unlike the original IO object, this can be an SSL layer or any other wrapper object).
			def io
				@ssl_socket
			end

			# makes sure any data in the que is send and calls `flush` on the socket, to make sure the buffer is sent.
			def flush
				begin
					send
					@ssl_socket.flush
				rescue => e
					
				end
			end

			# returns true if the service is disconnected
			def disconnected?
				(@socket.closed? || @ssl_socket.closed? || @socket.stat.mode == 0140222) rescue true # if mode is read only, it's the same as closed.
			end

			# identification markers

			#returns the service type - set to normal
			def service_type
				'ssl'
			end
			#returns true if the service is encrypted using the OpenSSL library.
			def ssl?
				true
			end

			#################
			# overide the followind methods for any child class.

			# this is a public method and it should be used by child classes to implement each
			# read(_nonblock) action. accepts one argument ::size for an optional buffer size to be read.
			def read size = 1048576
				data = ''
				begin
					loop { data << @ssl_socket.read_nonblock(size).to_s }
				rescue => e
					
				end
				return false if data.to_s.empty?
				touch
				data
			end

			protected

			# this is a protected method, it should be used by child classes to implement each
			# send action.
			def _send data
				@active_time += 7200
				@ssl_socket.write data
				touch
			end

			public

			# SSL certificate

			# returns the current self-signed certificate - or creates a new one, if there is no current certificate.
			def self.self_cert bits=2048, cn=nil, comment='a self signed certificate for when we only need encryption and no more.'
				@@self_cert ||= create_cert
				return *@@self_cert
			end
			#creates a self-signed certificate
			def self.create_cert bits=2048, cn=nil, comment='a self signed certificate for when we only need encryption and no more.'
				unless cn
					host_name = Socket::gethostbyname(Socket::gethostname)[0].split('.')
					cn = ''
					host_name.each {|n| cn << "/DC=#{n}"}
					cn << "/CN=#{host_name.join('.')}"
				end			
				# cn ||= "CN=#{Socket::gethostbyname(Socket::gethostname)[0] rescue Socket::gethostname}"

				rsa = OpenSSL::PKey::RSA.new(bits)
				cert = OpenSSL::X509::Certificate.new
				cert.version = 2
				cert.serial = 1
				name = OpenSSL::X509::Name.parse(cn)
				cert.subject = name
				cert.issuer = name
				cert.not_before = Time.now
				cert.not_after = Time.now + (365*24*60*60)
				cert.public_key = rsa.public_key

				ef = OpenSSL::X509::ExtensionFactory.new(nil,cert)
				ef.issuer_certificate = cert
				cert.extensions = [
				ef.create_extension("basicConstraints","CA:FALSE"),
				ef.create_extension("keyUsage", "keyEncipherment"),
				ef.create_extension("subjectKeyIdentifier", "hash"),
				ef.create_extension("extendedKeyUsage", "serverAuth"),
				ef.create_extension("nsComment", comment),
				]
				aki = ef.create_extension("authorityKeyIdentifier",
				                        "keyid:always,issuer:always")
				cert.add_extension(aki)
				cert.sign(rsa, OpenSSL::Digest::SHA1.new)

				return cert, rsa
			end
		end
	end
end
