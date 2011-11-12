# encoding: UTF-8
if defined?(Encoding) then
  Encoding.default_external = 'utf-8'
  Encoding.default_internal = 'utf-8'
else
  $KCODE = 'utf-8'
end

class Object
    # Return only the methods not present on basic objects
    def local_methods
        (self.methods - Object.new.methods).sort
    end
    
    def provides(methods=[])
        re=[]
        methods=[methods] unless methods.class == Array
        methods.each do |m|
            re += my_methods.map(&:to_s).grep(/#{m}/)
        end
        re
    end

    def provides?(method)
        if method.class == String
            my_methods.member? method.to_sym
        elsif method.class == Symbol
            my_methods.member? method
        end
    end

    # Return the provider of a method
    def whence(method)
        begin
            method=method.to_sym
        rescue
            puts "failed to convert method #{method} to sym"
        end
        (self.method(method).to_s.match(/\((.*)\)/) || [nil,self.class.to_s])[1]
    end
end

$LOAD_PATH << "#{ENV['HOME']}/bin/lib"
require 'std_helpers'
