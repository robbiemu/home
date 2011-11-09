# encoding: UTF-8

module Kernel
module_function
    
    def ri2(search)
        puts `ri2 #{search}`
    end
end

class String
    def putf(path='~/Desktop/irb_dump.txt')
      File.open(File.expand_path(path), 'w') { |fh| fh.write(self) }
    end
end

class Object
    # Return only the methods not present on basic objects
    def my_methods
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

module IRB
    class Notify
        attr_accessor :headers, :threshold
        def initialize(threshold=11, headers={})
            if headers.length == 0
                headers={
                    :header => {
                        :level => 0, 
                        :text => "[irbrc]"
                    },
                    :debug =>  {
                        :level => 10, 
                        :text => lambda{|this| "\e[0;32m#{this[:header][:text]}\e[0m"}
                    },
                    :warn => {
                        :level => 100, 
                        :text => lambda{|this| "\e[1;33m#{this[:header][:text]}\e[0m"}
                    },
                    :error => {
                        :level => 1000, 
                        :text => lambda{|this| "\e[1;31m#{this[:header][:text]}\e[0m"}
                    }
                }
            end
            @headers=headers
            @threshold=threshold
        end
        
        def get_level(sym)
            if @headers.key? sym
                return @headers[sym][:level]
            end
        end
        
        def get_header(threshold)
            header=nil
            if ((threshold.is_a? Symbol) && (@headers.key? threshold))
               header=@headers[threshold][:text]
            else
                @headers.values.each do |h|
                    if h[:level] <= threshold
                        header=h[:text]
                    end
                end
            end
            (header.is_a? Proc)? header.call(@headers): header
        end
        
        def notify (message, threshold=0)
            if threshold.is_a? Symbol
                if ((@headers.key? threshold) && (@headers[threshold][:level] >= @threshold))
                    header=@headers[threshold][:text]
                    header=(header.is_a? Proc)? header.call(@headers): header
                end
            elsif threshold >= @threshold #don't print the trivial
                header=get_header(threshold)
            end
            puts "#{header} #{message}" unless header.nil?
        end
    end
    class << self
        attr_accessor :notifier
        def notify(*args)
            notifier.notify(*args)
        end
    end
end
IRB.notifier=IRB::Notify.new

module IRB
    class SafeRequire
        attr_reader :loaded, :require_from
        def initialize(*lib_file)
            if not lib_file.empty?
                require_from lib_file
            end
            @loaded=[]
            @require_from={}
        end
        
        def lib_pack(lib)
            lib.each do |k,v|
                @require_from[k]=v
            end
        end

        def require_from(lib)
            rq(lib, "safe require library wrappers")
        end
        
        def require(*libs)
            libs.each do |lib|
                this=@require_from[lib]
                if this.key? :pre_proc
                    this[:pre_proc].yield
                end

                rval=self
                if this.key? :long_name
                    rval=rq this[:lib], this[:long_name]
                else
                    rval=rq this[:lib]
                end
                
                if ((this.key? :post_proc) && ( not rval.nil? ))
                    this[:post_proc].yield
                end
            end
        end        
    
        def rq(lib, name=nil)
            lib_name=(name.nil?)? lib: name.to_s
            begin
                Object.instance_method(:require).bind(self).call lib
                if name.nil?
                    IRB.notify("silently loading gem '#{lib}'", :debug)
                else
                    @loaded.push name
                end
            rescue LoadError => e
                pref = (name.nil?)? "": " (with «#{lib_name}»)"
                error = <<"EOF"
#{pref} could not load gem '#{lib}', Reason:
\t#{e.message} 
EOF
                IRB.notify(error, :error)
                nil
            end
            self
        end
    end
    
    class << self
        attr_accessor :srq
    end
end
IRB.srq=IRB::SafeRequire.new

#handy predefined objects
HASH = { 
  :bob => 'b', :mom => 'm', 
  :gods => 0, :devils => 1.0/0} unless defined?(HASH)
ARRAY = HASH.keys unless defined?(ARRAY)
IRB.notify("variables de conveniencia definidas: [\e[1;33mHASH, ARRAY\e[0m]", :warn)


