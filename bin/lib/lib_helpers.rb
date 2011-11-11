# encoding: UTF-8
IRB.srq.lib_pack(:awesome_print => {
    :lib => "awesome_print",
    :long_name => "color formatting",
    :post_proc => lambda {
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

        module Kernel
        module_function
            def ap(object, options = AwesomePrint.local_defaults)
                puts object.ai(options)
                object
            end
        end
        
        AwesomePrint.local_defaults({
          :multiline => false,
          :indent    => 2,
          :index     => false
        })

        IRB::Irb.class_eval do
            def output_value
                ap @context.last_value
            end
        end
    }
})

IRB.srq.lib_pack(:benchmark => {
    :lib => "benchmark",
    :post_proc => lambda{
        module Kernel
        module_function
            def time(repetitions=100, &block)
                Benchmark.bmbm do |b|
                    b.report {repetitions.times &block} 
                end
                nil
            end
        end
    },
})

IRB.srq.lib_pack(:bond => {
    :lib => "bond",
    :long_name => "tab completion for fs",
    :post_proc => lambda{
        begin
            Bond.start
        rescue LoadError => e
            IRB.notify("could not use Bond gem, falling back to irb/completion.\nReason:\n\t#{e.message}\n", :error)
            unless IRB.conf[:LOAD_MODULES].include?('irb/completion')
                IRB.conf[:LOAD_MODULES] << 'irb/completion'
            end
        end
    },
})

IRB.srq.lib_pack(:hirb => {
    :lib => "hirb",
    :post_proc => lambda{ Hirb.enable },
})

IRB.srq.lib_pack(:interactive_editor => {
    :lib => "interactive_editor",
    :long_name => "vi",
})

IRB.srq.lib_pack(:std_helpers => {
    :lib => "std_helpers",
    :long_name => "convenience methods for stdlib",
})
