# encoding: UTF-8
require 'rubygems' unless defined? Gem

# Highlighting and other features
require 'wirble' 
Wirble.init
Wirble.colorize

# Improved formatting for objects
require 'ap'

# Improved formatting for collections
require 'hirb'
Hirb.enable

require 'pp'

require 'irb/completion'
IRB.conf[:USE_READLINE] = true

#set up a history file ..one for each version of ruby we have installed
IRB.conf[:SAVE_HISTORY] = 1000
IRB.conf[:HISTORY_FILE] = "#{ENV['HOME']}/.#{$0}_history"
IRB.conf[:EVAL_HISTORY] = 200

IRB.conf[:AUTO_INDENT]=true

IRB.conf[:BACKTRACE_LIMIT]=6

IRB.conf[:PROMPT][:CUSTOM] = {
    :PROMPT_N => "#{$0}(%m):%03n % ", #indented
    :PROMPT_I => "#{$0}(%m):%03n % ", #normal
    :PROMPT_S => nil, #string continue
    :PROMPT_C => "#{$0}(%m):%03n % ", #statement continue
    :RETURN => "%s\n" #format return value
}
IRB.conf[:PROMPT_MODE]=:CUSTOM

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
end

#handy predefined objects
HASH = { 
  :bob => 'Marley', :mom => 'Barley', 
  :gods => 'Harley', :chris => 'Farley'} unless defined?(HASH)
ARRAY = HASH.keys unless defined?(ARRAY)
