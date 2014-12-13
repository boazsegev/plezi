module Anorexic

# test connections with: openssl s_client -connect localhost:3000

	# this class is a basic TCP socket service with SSL.
	#
	# a protocol should be assigned, or the service will fall back to an echo service.
	#
	# to-do: fix self certificate issue (fails).
	class SSLService < BasicService

		# instance methods

		attr_reader :ssl_socket

		# creates a new connection wrapper object for the new socket that was recieved from the `accept_nonblock` method call.
		def initialize soc, parameters = {}
			context = OpenSSL::SSL::SSLContext.new
			context.set_params verify_mode: OpenSSL::SSL::VERIFY_NONE# OpenSSL::SSL::VERIFY_PEER #OpenSSL::SSL::VERIFY_NONE
			# context.options DoNotReverseLookup: true
			if parameters[:ssl_cert] && parameters[:ssl_key]
				context.cert = parameters[:ssl_cert]
				context.key = parameters[:ssl_key]
			else
				context.cert, context.key = self.class.self_cert
			end
			context.cert_store = OpenSSL::X509::Store.new
			context.cert_store.set_default_paths
			@ssl_socket = OpenSSL::SSL::SSLSocket.new(soc, context)
			@ssl_socket.sync_close = true
			@socket = soc
			@ssl_socket.accept
			super
		end
		# identification markers

		#returns the service type - set to normal
		def service_type
			'encrypted'
		end
		#returns true if the service is encrypted using the OpenSSL library.
		def ssl?
			true
		end

		# returns an IO-like object used for reading/writing (unlike the original IO object, this can be an SSL layer or any other wrapper object).
		def io
			touch
			@ssl_socket
		end

		# reads from the connection
		def read size = 1048576
			data = ''
			begin
				loop { data << ssl_socket.read_nonblock( size) }
			rescue Exception => e
				
			end
			data
		end

		protected

		#sends data over the connection
		def _send data
			ssl_socket.write data
		end

		#closes the connection
		def _close
			ssl_socket.flush rescue true
			ssl_socket.close
		end

		# checks if the connection is closed
		def _disconnected?
			ssl_socket.closed? || ssl_socket.io.closed? || ssl_socket.io.stat.mode == 0140222 rescue true # if mode is read only, it's the same as closed.
		end


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

		# def self.cert_test
		# 	#Creating a CA
		# 	root_key = OpenSSL::PKey::RSA.new 2048 # the CA's public/private key
		# 	root_ca = OpenSSL::X509::Certificate.new
		# 	root_ca.version = 2 # cf. RFC 5280 - to make it a "v3" certificate
		# 	root_ca.serial = 1
		# 	root_ca.subject = OpenSSL::X509::Name.parse "/DC=org/DC=ruby-lang/CN=Ruby CA"
		# 	root_ca.issuer = root_ca.subject # root CA's are "self-signed"
		# 	root_ca.public_key = root_key.public_key
		# 	root_ca.not_before = Time.now
		# 	root_ca.not_after = root_ca.not_before + 2 * 365 * 24 * 60 * 60 # 2 years validity
		# 	ef = OpenSSL::X509::ExtensionFactory.new
		# 	ef.subject_certificate = root_ca
		# 	ef.issuer_certificate = root_ca
		# 	root_ca.add_extension(ef.create_extension("basicConstraints","CA:TRUE",true))
		# 	root_ca.add_extension(ef.create_extension("keyUsage","keyCertSign, cRLSign", true))
		# 	root_ca.add_extension(ef.create_extension("subjectKeyIdentifier","hash",false))
		# 	root_ca.add_extension(ef.create_extension("authorityKeyIdentifier","keyid:always",false))
		# 	root_ca.sign(root_key, OpenSSL::Digest::SHA256.new)
		# 	#Creating an End-Point Certificate
		# 	key = OpenSSL::PKey::RSA.new 2048
		# 	cert = OpenSSL::X509::Certificate.new
		# 	cert.version = 2
		# 	cert.serial = 2
		# 	cert.subject = OpenSSL::X509::Name.parse "/DC=org/DC=ruby-lang/CN=Ruby certificate"
		# 	cert.issuer = root_ca.subject # root CA is the issuer
		# 	cert.public_key = key.public_key
		# 	cert.not_before = Time.now
		# 	cert.not_after = cert.not_before + 1 * 365 * 24 * 60 * 60 # 1 years validity
		# 	ef = OpenSSL::X509::ExtensionFactory.new
		# 	ef.subject_certificate = cert
		# 	ef.issuer_certificate = root_ca
		# 	cert.add_extension extension_factory.create_extension('keyUsage', 'keyEncipherment,dataEncipherment,digitalSignature')
		# 	cert.add_extension(ef.create_extension("subjectKeyIdentifier","hash",false))
		# 	cert.sign(root_key, OpenSSL::Digest::SHA256.new)

		# 	# #Creating a Certificate
		# 	# name = OpenSSL::X509::Name.parse 'CN=localhost/DC=localhost'
		# 	# cert = OpenSSL::X509::Certificate.new
		# 	# cert.version = 2
		# 	# cert.serial = 0
		# 	# cert.not_before = Time.now
		# 	# cert.not_after = Time.now + 3600
		# 	# key = OpenSSL::PKey::RSA.new 2048
		# 	# cert.public_key = key.public_key
		# 	# cert.subject = name

		# 	# # Certificate Extensions
		# 	# cert.add_extension extension_factory.create_extension('basicConstraints', 'CA:FALSE', true)
		# 	# cert.add_extension extension_factory.create_extension('keyUsage', 'keyEncipherment,dataEncipherment,digitalSignature')
		# 	# cert.add_extension extension_factory.create_extension('subjectKeyIdentifier', 'hash')

		# 	# # Signing a Certificate
		# 	# cert.issuer = name
		# 	# cert.sign key, OpenSSL::Digest::SHA1.new

		# 	#server
		# 	context = OpenSSL::SSL::SSLContext.new
		# 	context.cert = cert
		# 	context.key = key
		# 	tcp_server = TCPServer.new 8080
		# 	ssl_server = OpenSSL::SSL::SSLServer.new tcp_server, context
		# 	ssl_socket = ssl_server.accept
		# end
	end
end
