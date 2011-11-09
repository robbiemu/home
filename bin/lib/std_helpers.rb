# encoding: UTF-8

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

class Object
    # Give every object a rudimentary deep clone
    def deep_clone
        Marshal.load( Marshal.dump(self) )
    end
end
