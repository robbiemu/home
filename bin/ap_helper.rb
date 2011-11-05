class AwesomePrint
    @@class_options={:color=>{}}
    def self.local_defaults(options={})
        @@class_options[:color].merge!(options.delete(:color) || {})
        @@class_options.merge!(options)
        Marshal.load( Marshal.dump(@@class_options) )
    end
    def awesome_hash(h)
        return "{}" if h == {}

        keys = @options[:sorted_hash_keys] ? h.keys.sort { |a, b| a.to_s <=> b.to_s } : h.keys
        data = keys.map do |key|
            plain_single_line do
                [ awesome(key), h[key], key ]
            end
        end
      
        width = data.map { |key, | key.size }.max || 0
        width += @indentation if @options[:indent] > 0
  
        data = data.map do |key, value, hkey|
            if @options[:multiline]
                formatted_key = (@options[:indent] >= 0 ? key.rjust(width).sub!(/#{key}/, awesome(hkey)) : indent + key.ljust(width)).sub!(/#{key}/, awesome(hkey))
            else
                formatted_key = awesome(hkey)
            end
            indented do
                formatted_key << colorize(" => ", :hash) << awesome(value)
            end
        end
        if @options[:multiline]
            "{\n" << data.join(",\n") << "\n#{outdent}}"
        else
            "{ #{data.join(', ')} }"
        end
    end
end

class APHelper
end

module Kernel
    def ap(object, options = AwesomePrint.local_defaults)
        puts object.ai(options)
        object
    end
end
