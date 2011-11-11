# encoding: UTF-8

class String
    def to_regexp
        /#{self}/
    end
    
    %w(gray red green yellow blue purple cyan white).each_with_index do |color, i|
        const_set(color.upcase.to_sym, "\033[1;#{30+i}m")
    end
    %w(black darkred darkgreen brown navy darkmagenta darkcyan lightgray).each_with_index do |color, i|
        const_set(color.upcase.to_sym, "\033[0;#{30+i}m")
    end
    DARKGRAY=GRAY
    RESET="\033[0m"

    def color(colorname)
        color=self.class.const_get(colorname.upcase.to_sym)
        "#{color}#{self}#{RESET}"
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
