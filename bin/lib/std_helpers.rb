# encoding: UTF-8

class Object
    # Return only the methods not present on basic objects
    def local_methods
        (self.methods - Object.new.methods).sort
    end

    # Return only exposed methods defined in the class, not in its ancestors    
    def class_methods
        self.methods.select {|m| not 0.1.method(m).to_s.match /\((.*)\)/}
    end
    
    def provides(methods=[], type=:local)
        type = :class if type != :local
        re=[]
        methods=[methods] unless methods.class == Array
        methods.each do |m|
            re += self.send("#{type}_methods").map(&:to_s).grep(/#{m}/).map(&:to_sym)
        end
        re
    end

    def provides?(method, type=:local)
        type = :class if type != :local
        if method.class == String
            self.send("#{type}_methods").member? method.to_sym
        elsif method.class == Symbol
            self.send("#{type}_methods").member? method
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

    # Give every object a rudimentary deep clone
    def deep_clone
        Marshal.load( Marshal.dump(self) )
    end
end

module Hooker
    module ClassMethods
    private
        def following(*syms, &block)
            syms.each do |sym| # For each symbol
                str_id = "__#{sym}__hooked__"
                unless private_instance_methods.include?(str_id)
                    alias_method str_id, sym        # Backup original method
                    private str_id                  # Make backup private
                    define_method sym do |*args|    # Replace method
                        ret = __send__ str_id, *args  # Invoke backup
                        rval=block.call(self,              # Invoke hook
                          :method => sym, 
                          :args => args,
                          :return => ret
                        )
                        if not rval.nil?
                            ret=rval[:ret]
                        end
                        ret # Forward return value of method
                    end
                end
            end
        end
    end
    
    def Hooker.included(base)
        base.extend(ClassMethods)
    end
end

if 0.1**2 != 0.01 # patch Float so it works by default
    class Float   # known issues:
        include Hooker #                 eval( float.** n ) throws a stack too deep
        0.1.class_methods.each do |op| # float - n does not call like: float.send(:-, n)
            if ( (not [:rationalize].member? op) and
                 (0.1.method(op).arity != 0) and (0.1.whence(op) == "Float"))
                following op do |receiver, args|
                    if args[:return].is_a? Float
                        argsin=[]
                        args[:args].each do |c|
                            argsin=c.rationalize
                        end
                        rval=receiver.rationalize.send(
                                args[:method], 
                                argsin
                             )
                        ret=Hash[:ret => rval.to_f]
                    end
                    ret
                end
            end
        end
    end
end

class Numeric 
   def to_hex 
      to_s(16) 
   end 
   def to_oct 
      to_s(8) 
   end
end

class String
    def to_regexp
        /#{self}/
    end
end

class Regexp
    # Convenience method on Regexp so you can do
    # /an/.show_match("banana") # => "b<<an>>ana" 
    def show_match(str)
      if self =~ str then
        "#{$`}<<#{$&}>>#{$'}"
      else
        "no match"
      end
    end
    
    def to_regexp
        self
    end
end

class Array
    def duplicates
        self.group_by { |e| e }.select { |k,v| v.size > 1 }.map(&:first)
    end
end

class Hash
    def kmap(*args, &block)
        Hash[*self.keys.map(*args, &block).zip( self.values ).flatten]
    end
    def vmap(*args, &block)        
        Hash[*self.keys.zip( self.values.map(*args, &block) ).flatten]
    end
    def hmap(*args, &block)
        Hash[*self.keys.map(*args, &block).zip( self.values.map(*args, &block) ).flatten]
    end

    def kmap!(*args, &block)
        h=kmap(*args, &block)
        self.clear
        self.merge!(h)
    end
    def vmap!(*args, &block)
        h=vmap(*args, &block)
        self.clear
        self.merge!(h)
    end
    def hmap!(*args, &block)
        h=hmap(*args, &block)
        self.clear
        self.merge!(h)
    end
end
