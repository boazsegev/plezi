require 'plezi/activation'
require 'plezi/router/router'

module Plezi
   module_function

  # attempts to convert a string's encoding to UTF-8, but only when the string is a valid UTF-8 encoded string.
  def try_utf8!(string, encoding = ::Encoding::UTF_8)
     return nil unless string
     string.force_encoding(::Encoding::ASCII_8BIT) unless string.force_encoding(encoding).valid_encoding?
     string
  end

  # Sanitizes hash data, attempting to "rubyfy" any Hash Strings to reversible Ruby objects. i.e:
  #
  #          {"go" => "<tag>home</tag>", "now" => "false", "count" => "8", "float" => "0.7", "empty" => ""}
  #
  # Will become:
  #
  #          {go: "&lt;tag>home&lt;/tag&gt;", now: false, count: 8, float: "0.7", empty: nil}
  #
  # As you may notice, float Strings aren't "rubyfied". Any "rubyfied" object will revert back to the same String form using `to_s`.
  def rubyfy(hash)
     case hash
     when Hash
        cpy = Hash.new(&hash_proc_4symstr)
        hash.each { |k, v| cpy[k.is_a?(String) ? k.to_sym : k] = rubyfy(v) }
        hash = cpy
     when String
        hash = if hash.empty?
                  nil
               elsif hash.to_i.to_s == hash
                  hash.to_i
               elsif hash == 'true'.freeze
                  true
               elsif hash == 'false'.freeze
                  false
               else
                  ERB::Util.h try_utf8!(hash)
               end
     when Array
        hash = hash.map { |i| rubyfy(i) }
     end
     hash
  end

  # Catches String/Symbol mixups. Add this to any Hash using Hash#default_proc=
  def hash_proc_4symstr
     @hash_proc_4symstr ||= proc do |hash, key|
        case key
        when String
           tmp = key.to_sym
           hash.key?(tmp) ? hash[tmp] : nil
        when Symbol
           tmp = key.to_s
           hash.key?(tmp) ? hash[tmp] : nil
        end
     end
  end
end
