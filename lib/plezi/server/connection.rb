# encoding: UTF-8



module Plezi

	class Connection
		attr_reader :socket, :ssl_socket, :params, :active_time, :out_que, :locker
		attr_accessor :protocol, :handler, :timeout

		def initialize socket, params
			@ssl_socket, @socket, @params = false, socket, params
			@handler = params[:handler]
			# socket.setsockopt Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, "\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" #== [10 sec 0 usec].pack '1_2'
			@out_que = []
			@locker = Mutex.new
			@protocol = params[:protocol].is_a?(Class) ? (params[:protocol].new self, params) : params[:protocol]
			@protocol.on_connect if @protocol.is_a?(HTTPProtocol)
			touch
			@timeout ||= 5
		end

		def call
			# don't let competing threads do the same job.
			return false if @locker.locked?
			begin
				@locker.synchronize do
					return disconnect if disconnected?
					protocol.on_message
				end

			rescue Exception => e
				return disconnect
			end
		end

		def clear?
			return false unless timedout? || disconnected?
			on_disconnect
		end

		# checks if a connection timed out
		def timedout?
			Time.now - @active_time > @timeout.to_i
		end

		# resets the timer for the connection timeout
		def touch
			@active_time = Time.now
		end

		# returns an IO-like object used for reading/writing (unlike the original IO object, this can be an SSL layer or any other wrapper object).
		def io
			@socket
		end

		# sends data immidiately - forcing the data to be sent, flushing any pending messages in the que
		def send data = nil
			return if @out_que.empty? && data.nil?
			@locker.synchronize do
				unless @out_que.empty?
					@out_que.each { |d| _send d rescue disconnect }
					@out_que.clear					
				end
				(_send data rescue disconnect) if data
				touch
			end
		end

		# sends data without waiting - data might be sent in a different order then intended.
		def send_nonblock data
			touch
			@locker.synchronize {@out_que << data}
			EventMachine.queue [], method(:send)
		end

		# adds data to the out buffer - but doesn't send the data until a send event is called.
		def << data
			touch
			@locker.synchronize {@out_que << data}
		end

		# makes sure any data in the que is send and calls `flush` on the socket, to make sure the buffer is sent.
		def flush
			begin
				send
				@socket.flush				
			rescue => e
				
			end
		end

		# called once a socket is disconnected or needs to be disconnected.
		def on_disconnect
			Plezi.run_async { EventMachine.remove_io @socket }
			@locker.synchronize do
				@out_que.each { |d| _send d rescue true}
				@out_que.clear
			end
			EventMachine.queue [], protocol.method(:on_disconnect) if protocol && !protocol.is_a?(Class)
			close
		end

		# status markers

		# closes the connection
		def close
			@locker.synchronize do
				io.flush rescue true
				io.close rescue true
			end
		end
		# returns true if the service is disconnected
		def disconnected?
			@socket.closed? rescue true # || socket.stat.mode == 0140222 rescue true # if mode is read only, it's the same as closed.
		end
		# disconects the service.
		def disconnect
			EventMachine.queue [], method(:on_disconnect)
		end
		# returns true if the socket has content to be read.
		def has_incoming_data?
			 (@socket.stat.size > 0) rescue false
		end


		# identification markers

		#returns the service type - set to normal
		def service_type
			'normal'
		end
		#returns true if the service is encrypted using the OpenSSL library.
		def ssl?
			false
		end

		#################
		# overide the followind methods for any child class.

		# this is a public method and it should be used by child classes to implement each
		# read(_nonblock) action. accepts one argument ::size for an optional buffer size to be read.
		def read size = 1048576
			begin
				data = @socket.recv_nonblock( size )
				return false if data.to_s.empty?
				touch
				data
			rescue Exception => e
				
			end
		end

		protected

		# this is a protected method, it should be used by child classes to implement each
		# send action.
		def _send data
			# data.force_encoding "binary" rescue false
			touch
			len = data.bytesize
			act = @socket.send data, 0
			while len > act
				act += @socket.send data.byteslice(act..-1) , 0
				touch
			end
		end

	end

	class SSLConnection < Connection
		attr_reader :ssl_socket

		def initialize socket, params
			if params[:ssl] || params[:ssl_key] || params[:ssl_cert]
				params[:ssl_cert], params[:ssl_key] = Connection.self_cert unless params[:ssl_key] && params[:ssl_cert]
				context = OpenSSL::SSL::SSLContext.new
				context.set_params verify_mode: OpenSSL::SSL::VERIFY_NONE# OpenSSL::SSL::VERIFY_PEER #OpenSSL::SSL::VERIFY_NONE
				# context.options DoNotReverseLookup: true
				context.cert, context.key = params[:ssl_cert], params[:ssl_key]
				context.cert_store = OpenSSL::X509::Store.new
				context.cert_store.set_default_paths
				@ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, context)
				@ssl_socket.sync_close = true
				@ssl_socket.accept
			end
			raise "Not an SSL connection" unless ssl_socket
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

		def close
			@locker.synchronize do
				io.flush rescue true
				io.close rescue true
			end
		end
		# returns true if the service is disconnected
		def disconnected?
			@socket.closed? || @ssl_socket.closed? rescue true # || socket.stat.mode == 0140222 rescue true # if mode is read only, it's the same as closed.
		end
		# disconects the service.
		def disconnect
			EventMachine.queue [], method(:on_disconnect)
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
				loop { data << @ssl_socket.read_nonblock( size) }
				return false if data.to_s.empty?
				touch
				data
			rescue Exception => e
				
			end
		end

		protected

		# this is a protected method, it should be used by child classes to implement each
		# send action.
		def _send data
			@ssl_socket.write data
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
