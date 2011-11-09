# encoding: UTF-8
if defined?(Encoding) then
  Encoding.default_external = 'utf-8'
  Encoding.default_internal = 'utf-8'
else
  $KCODE = 'utf-8'
end

irbrc_message_state="error"
irbrc_header="[irbrc]"
irbrc_error_header="\e[1;31m#{irbrc_header}\e[0m"
irbrc_warn_header="\e[1;33m#{irbrc_header}\e[0m"
irbrc_debug_header="\e[0;32m#{irbrc_header}\e[0m"

requires=[
#    {:hirb => {:lib => 'hirb', :post => lambda { Hirb.enable}}},
    {:vi => 'interactive_editor'}, 
    {:bond => 'bond'}, 
    {:benchmark => 'benchmark'}, 
    {:ap => 'awesome_print'},
    "#{ENV['HOME']}/bin/ap_helper", #Strings don't list as included at startup
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
            puts <<"EOF"
#{@error}#{pref} could not load gem '#{lib}',
"#{path.inspect}" in '#{__FILE__}:#{__LINE__-2}' Reason:
\t#{e.message}
 
EOF
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

# table formatting, auto-pager
    #auto-pager usually broken
if defined? Hirb
    Hirb.enable
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
#IRB.conf[:HISTORY_FILE] = "#{ENV['HOME']}/.#{$0}_history"
IRB.conf[:SAVE_HISTORY] = 1000
IRB.conf[:EVAL_HISTORY] = 200
IRB.conf[:REJECT_HISTORY] = [ 
    /^history/, 
    /^h\!/, 
    /^\s+/, 
    /^(?:exit|quit)\s*$/ 
] #custom

# clean history and write it out:
IRB.conf[:AT_EXIT] << proc { 
    new_history=[]
    uniq_history=Readline::HISTORY.sort.uniq.deep_clone
    Readline::HISTORY.to_a.each do |cmd| 
        if uniq_history.include? cmd
            new_history.push cmd
            uniq_history.delete cmd
        end
    end
    IRB.conf[:REJECT_HISTORY].each do |r|
        new_history.reject! {|x| x =~ r}
    end
    verbose=$VERBOSE
    $VERBOSE=nil
    Readline::HISTORY=new_history
    $VERBOSE=verbose
}

IRB.conf[:PROMPT][:CUSTOM] = {
    :PROMPT_N => "#{$0}(%m):%03n % ", #indented
    :PROMPT_I => "#{$0}(%m):%03n \001\e[1;33m\002%\001\e[0m\002 ", #normal
    :PROMPT_S => nil, #string continue
    :PROMPT_C => "#{$0}(%m):%03n % ", #statement continue
    :RETURN => "%s\n" #format return value
}
IRB.conf[:PROMPT_MODE]=:CUSTOM

module Kernel
module_function
    
    def ri2(search)
        puts `ri2 #{search}`
    end

    def history
        i=0; 
        Readline::HISTORY.to_a.each do |x| 
            i+=1; 
            puts "[#{i.to_s.send(:white)}] #{x.send(:yellowish)}\n" 
        end
        Readline::HISTORY
    end

    def h!(arg=(Readline::HISTORY.to_a.length), sym=:list)
        case arg
        when Fixnum then
            i=arg-1
            puts Readline::HISTORY.to_a[i]
            eval(Readline::HISTORY.to_a[i], conf.workspace.binding)
        when String, Regexp then
            arexp = arg.to_regexp
            case sym
            when :list then
                i=0
                outp=[]
                Readline::HISTORY.to_a[0..-2].each do |cmd| 
                    i+=1; 
                    outp.push [cmd, "[#{i.to_s.send(:white)}] #{cmd.send(:yellowish)}\n"]
                end
                outp.select {|cmd| cmd[0] =~ arexp }.each do |selected|
                    print selected[1]
                end
                Readline::HISTORY
            when :exec then
                eval(Readline::HISTORY.to_a.select {|cmd| cmd =~ arexp }[-2], conf.workspace.binding)
            end
        end    
    end
end
alias quit exit

class String
    def putf(path='~/Desktop/irb_dump.txt')
      File.open(File.expand_path(path), 'w') { |fh| fh.write(self) }
    end

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
        (self.method(method).to_s.match(/\((.*)\)/) || [nil,self.class.to_s])[1]
    end

    # Give every object a rudimentary deep clone
    def deep_clone
        Marshal.load( Marshal.dump(self) )
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
