# encoding: UTF-8

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

class Object
    # Give every object a rudimentary deep clone
    def deep_clone
        Marshal.load( Marshal.dump(self) )
    end
end
