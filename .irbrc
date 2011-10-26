# encoding: UTF-8
irbrc_header="[irbrc]"
irbrc_error_header="\033[1;31m#{irbrc_header}\033[0m"
irbrc_warn_header="\033[1;33m#{irbrc_header}\033[0m"
irbrc_debug_header="\033[0;32m#{irbrc_header}\033[0m"

requires=['wirble', 'ap', 'hirb', 'bond']
requires.insert(0,'rubygems') unless defined? Gem

loaded=[]
requires.each do |lib|
    begin
    require lib
    loaded.push lib
    rescue LoadError => e
        puts "#{irbrc_error_header} could not load gem '#{lib}', reason:\n\t#{e.message}\n\n"
    end
end

# Highlighting and other features
Wirble.init
Wirble.colorize

# Improved formatting for collections
Hirb.enable

# tab completion for filesystem
begin
    Bond.start
rescue LoadError => e
    puts "#{irbrc_error_header} could not load gem '#{lib}', reason:\n\t#{e.message}\n\n"
    unless IRB.conf[:LOAD_MODULES].include?('irb/completion')
        IRB.conf[:LOAD_MODULES] << 'irb/completion'
    end
end

puts "#{irbrc_header} gems para su holgura -  #{loaded}";

IRB.conf[:AUTO_INDENT]=true

IRB.conf[:BACKTRACE_LIMIT]=6

#set up a history file ..one for each version of ruby we have installed
IRB.conf[:SAVE_HISTORY] = 1000
IRB.conf[:HISTORY_FILE] = "#{ENV['HOME']}/.#{$0}_history"
IRB.conf[:EVAL_HISTORY] = 200

IRB.conf[:PROMPT][:CUSTOM] = {
    :PROMPT_N => "#{$0}(%m):%03n % ", #indented
    :PROMPT_I => "#{$0}(%m):%03n \033[1;33m%\033[0m ", #normal
    :PROMPT_S => nil, #string continue
    :PROMPT_C => "#{$0}(%m):%03n % ", #statement continue
    :RETURN => "%s\n" #format return value
}
IRB.conf[:PROMPT_MODE]=:CUSTOM

def ri2(search)
    puts `ri2 #{search}`
end

# Benchmarking helper (http://ozmm.org/posts/time_in_irb.html)
if defined? Benchmark
    def time(repetitions=100, &block)
        Benchmark.bmbm do |b|
            b.report {repetitions.times &block} 
        end
        nil
    end
end

class Object
    # Return only the methods not present on basic objects
    def my_methods
        (self.methods - Object.instance_methods).sort
    end
    
    def provides(methods=[])
        re=[]
        methods=[methods] unless methods.class == Array
        methods.each do |m|
            re += my_methods.map(&:to_s).grep(m)
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
end

#handy predefined objects
HASH = { 
  :bob => 'Marley', :mom => 'Barley', 
  :gods => 'Harley', :chris => 'Farley'} unless defined?(HASH)
ARRAY = HASH.keys unless defined?(ARRAY)
puts "#{irbrc_header} convenience vars:"
print Wirble::Colorize.colorize_string "  HASH ", :light_green
p HASH;
print Wirble::Colorize.colorize_string "  ARRAY ", :light_green 
p ARRAY;
