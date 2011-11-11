class String    
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

module Kernel
module_function
    alias :_p :p
    def p(*args)
        args[0..-2].each do |o|
            STDOUT.write("#{o.inspect}#{$/}")
        end
        args.last
    end
    
    alias :_puts :puts
    def puts(*args)
        args.each do |o|
            STDOUT.write("#{o.to_s}#{$/}")
        end
        args[0..-2].each {|o| STDOUT.write("#{o.inspect}#{$/}") }
        args.last
    end
end

class Object
    alias :_inspect :inspect    
    def object_inspect(recycle=nil)
        x = (recycle.nil?)? _inspect : recycle.to_s
        x.sub!(/#{self.class}/, self.class.inspect) || _inspect
        x=x.gsub(/(^#<|>$)/, '\1'.to_s.color(:lightgray)).gsub(/(\@\S+)(=)/, '\1 \2 ')
    end
    def inspect
        object_inspect 
    end
end

class Class
    alias :_inspect :inspect
    def inspect
        to_s.color(:yellow)
    end    
end

class Proc
    alias :_proc_level_inspect :inspect
    def inspect
        x=_inspect
        if x =~ /\(lambda\).*\>/
            x.sub!(/^(.*?\:.*?)\@.*(\(lambda\).*\>)$/, '\1 \2')
            x.sub!("lambda", "lambda".color(:yellow))
        else
            x=x.sub(/^(.*?\:.*?)\@.*(\s*\>)$/, '\1\2')
        end
        object_inspect(x)
    end
end

class NilClass
    alias :_inspect :inspect
    def inspect
        "nil".color(:red)
    end
    def to_s
        "nil"
    end
end

class TrueClass
    alias :_inspect :inspect
    def inspect
        "true".color(:green)
    end
    def to_s
        "true"
    end
end

class FalseClass
    alias :_inspect :inspect
    def inspect
        "false".color(:red)
    end
    def to_s
        "false"
    end
end

class Symbol
    alias :_inspect :inspect
    def inspect
        "#{':'.color(:lightgray)}#{self.id2name.color(:darkcyan)}"
    end
end

class String
    def putf(path='~/Desktop/irb_dump.txt')
      File.open(File.expand_path(path), 'w') { |fh| fh.write(self) }
    end
    
    alias :_inspect :inspect    
    def inspect
        "#{'"'.color(:gray)}#{self.to_s.color(:brown)}#{'"'.color(:gray)}"
    end
end

class Numeric
    alias :_inspect :inspect
    def inspect
        "#{self.to_s.color(:blue)}"
    end
end

class Hash
    alias :_inspect :inspect
    def inspect
        outp=[]
        pairing="=>".color(:navy)
        self.each do |k,v|
            if v.is_a? String
                v=v.dump.gsub!(/^"|"$/, "")
            end
            if k.is_a? String
                k=k.dump.gsub!(/^"|"$/, "")
            end
            outp.push "#{k.inspect} #{pairing} #{v.inspect}"
        end
        "{".color(:navy) + outp.join(", ") + "}".color(:navy)
    end

    alias :_to_s :to_s
    def to_s
        outp=[]
        self.each do |k,v|
            case k
            when Symbol then
                k=":#{k}"
            when String then
                k=%|"#{k}"|
            end
            case v
            when Symbol then
                v=":#{v}"
            when String then
                v=%|"#{v}"|
            end
            outp.push "#{k.to_s}=>#{v.to_s}"
        end
        "{#{outp.join(", ")}}"
    end
end

class Array
    alias :_inspect :inspect
    def inspect
        outp=[]
        self.each do |c|
            if c.is_a? String
                c=c.dump.gsub!(/^"|"$/, "")
            end
            outp.push "#{c.inspect}"
        end
        "[".color(:darkgreen) + outp.join(", ") + "]".color(:darkgreen)
    end
    
    alias :_to_s :to_s
    def to_s
        outp=[]
        self.each do |c|
            case c
            when Symbol then
                c=":#{c}"
            when String then
                c=%|"#{c}"|
            end
            outp.push "#{c.to_s}"
        end
        "[#{outp.join(", ")}]"
    end
end
