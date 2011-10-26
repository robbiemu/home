# encoding: UTF-8
requires=['wirble', 'ap', 'hirb', 'pp', 'bond']
requires.insert(0,'rubygems') unless defined? Gem

requires.each do |lib|
    begin
    require lib
    rescue LoadError => e
        puts "\033[1;31m[irbrc]\033[0m could not load gem '#{lib}', reason:\n\t#{e.message}\n\n"
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
rescue LoadError
    unless IRB.conf[:LOAD_MODULES].include?('irb/completion')
        IRB.conf[:LOAD_MODULES] << 'irb/completion'
    end
end

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
puts "convenience vars:"
puts "HASH#{HASH}"
puts "ARRAY#{ARRAY}"
