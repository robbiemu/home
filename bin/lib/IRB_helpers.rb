# encoding: UTF-8
require 'IRB_colors'

module Kernel
module_function
    def ri2(search)
        puts `ri2 #{search}`
    end
    
    def history
        i=0; 
        Readline::HISTORY.to_a.each do |x| 
            i+=1; 
            puts "[#{i.to_s.color(:white)}] #{x.color(:brown)}" 
        end
        Readline::HISTORY
    end

    def h!(arg=(Readline::HISTORY.to_a.length), sym=:list)
        case arg
        when Fixnum then
            i=arg-1
            puts Readline::HISTORY.to_a[i]
            eval(Readline::HISTORY.to_a[i], conf.workspace.binding)
        when String, Regexp then
            arexp = arg.to_regexp
            case sym
            when :list then
                i=0
                outp=[]
                Readline::HISTORY.to_a[0..-2].each do |cmd| 
                    i+=1; 
                    outp.push [cmd, "[#{i.to_s.color(:white)}] #{cmd.color(:brown)}\n"]
                end
                outp.select {|cmd| cmd[0] =~ arexp }.each do |selected|
                    print selected[1]
                end
                Readline::HISTORY
            when :exec then
                eval(Readline::HISTORY.to_a.select {|cmd| cmd =~ arexp }[-2], conf.workspace.binding)
            end
        end    
    end
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
                        :text => Proc.new{|this| this[:header][:text].color(:green)}
                    },
                    :warn => {
                        :level => 100, 
                        :text => lambda{|this| this[:header][:text].color(:yellow)}
                    },
                    :error => {
                        :level => 1000, 
                        :text => lambda{|this| this[:header][:text].color(:red)}
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
IRB.notify("variables de conveniencia definidas: [" + "HASH".color(:darkcyan) + "," + " ARRAY".color(:darkgreen) + "]", :warn)


