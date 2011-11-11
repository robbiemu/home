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
        x.sub!(/#{self.class}/, self.class.to_s.color(:yellow)) || _inspect
        x=x.gsub(/(^#<|>$)/, '\1'.to_s.color(:lightgray)).gsub(/(\s*=>{0,1}\s*)/, ' \1 '.to_s.color(:navy))
    end
    def inspect
        object_inspect 
    end
end

class Proc
    alias :_inspect :inspect
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

class String
    def putf(path='~/Desktop/irb_dump.txt')
      File.open(File.expand_path(path), 'w') { |fh| fh.write(self) }
    end
    
    alias :_inspect :inspect    
    def inspect
        "#{'"'.color(:gray)}#{self.to_s.color(:brown)}#{'"'.color(:gray)}"
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

class Symbol
    alias :_inspect :inspect
    def inspect
        "#{':'.color(:lightgray)}#{self.id2name.color(:darkcyan)}"
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
        object_inspect
    end
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
            outp.push "#{k.to_s} => #{v.to_s}"
        end
        "{#{outp.join(", ")}}"
    end
end

class Array
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
