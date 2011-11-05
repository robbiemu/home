# encoding: UTF-8
irbrc_message_state="error"
irbrc_header="[irbrc]"
irbrc_error_header="\033[1;31m#{irbrc_header}\033[0m"
irbrc_warn_header="\033[1;33m#{irbrc_header}\033[0m"
irbrc_debug_header="\033[0;32m#{irbrc_header}\033[0m"

requires=[
    {:vi => 'interactive_editor'}, 
    {:bond => 'bond'}, 
    {:benchmark => 'benchmark'}, 
    {:ap => 'awesome_print'},
    "#{ENV['HOME']}/bin/ap_helper"
]
requires.insert(0, {:gem => 'rubygems'}) unless defined? Gem

class SafeRequire
    attr_reader :loaded
    def initialize(message_state, error, warn, debug)
        @loaded=[]
        @message_state=message_state
        @error=error
        @warn=warn
        @debug=debug
    end
    
    def rq(lib, name=nil)
        lib_name=(name.nil?)? lib: name.to_s
        begin
            require lib
            if name.nil?
                if @message_state == "debug"
                    puts "#{@debug} silently loading gem '#{lib}'\n"  
                end
            else
                @loaded.push name
            end
        rescue LoadError => e
            pref = (name.nil?)? "": " (with «#{lib_name}»)"
            puts "#{@error}#{pref} could not load gem '#{lib}', reason:\n\t#{e.message}\n\n"
        end
    end
end

srq=SafeRequire.new(irbrc_message_state, irbrc_error_header, irbrc_warn_header, irbrc_debug_header)
requires.each do |h|
    if h.class == String
        srq.rq h
    else
        h.map do |name, lib|
            srq.rq lib, name
        end
    end
end

# tab completion for filesystem
if defined? Bond
    begin
        Bond.start
    rescue LoadError => e
        puts "#{irbrc_error_header} could not use Bond gem, falling back to irb/completion.\nReason:\n\t#{e.message}\n\n"
        unless IRB.conf[:LOAD_MODULES].include?('irb/completion')
            IRB.conf[:LOAD_MODULES] << 'irb/completion'
        end
    end
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

# Highlighting and other features
if defined? APHelper
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
    print "#{irbrc_header} para su holgura -  "
    ap srq.loaded
else
    puts "#{irbrc_header} para su holgura -  #{srq.loaded}";
end

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

alias quit exit

def ri2(search)
    puts `ri2 #{search}`
end

class Object
    # Return only the methods not present on basic objects
    def my_methods
        (self.methods - Object.new.methods).sort
    end
    
    def provides(methods=[])
        re=[]
        methods=[methods] unless methods.class == Array
        methods.each do |m|
            re += my_methods.map(&:to_s).grep(/#{m}/)
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

    # Return the provider of a method
    def whence(method)
        begin
            method=method.to_sym
        rescue
            puts "failed to convert method #{method} to sym"
        end
        self.method(method).to_s.match(/\((.*)\)/)[1]
    end
end

#handy predefined objects
HASH = { 
  :bob => 'b', :mom => 'm', 
  :gods => 0, :devils => 1.0/0} unless defined?(HASH)
ARRAY = HASH.keys unless defined?(ARRAY)
puts "#{irbrc_header} convenience vars:"
print "   HASH ".send(:yellow)
ap HASH
print "  ARRAY ".send(:yellow)
ap ARRAY
