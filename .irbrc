# encoding: UTF-8
if defined?(Encoding) then
  Encoding.default_external = 'utf-8'
  Encoding.default_internal = 'utf-8'
else
  $KCODE = 'utf-8'
end


#§ irb-specific monkey patches

class String
    %w(gray red green yellow blue purple cyan white).each_with_index do |color, i|
        const_set(color.upcase.to_sym, [1, 30+i])
    end
    %w(black darkred darkgreen brown navy darkmagenta darkcyan lightgray).each_with_index do |color, i|
        const_set(color.upcase.to_sym, [0, 30+i])
    end
    DARKGRAY=GRAY
    RESET="\e[0m"

    def color(colorname)
        color=String.const_get(colorname.upcase.to_sym)
        color="\e[#{color[0]};#{color[1]}m"
        "#{color}#{self}#{RESET}"
    end
    
    def bg_color(colorname)
        color=String.const_get(colorname.upcase.to_sym)
        color="\e[#{color[0]};#{color[1]+10}m"
        "#{color}#{self}#{RESET}"
    end
end

module Kernel
module_function
    def ri2(search)
        puts `ri2 #{search}`
    end
    
    def history #requires some IRB.conf settings near end of irbrc
        i=0; 
        Readline::HISTORY.to_a.each do |x| 
            i+=1; 
            puts "[#{i.to_s.color(:white)}] #{x.color(:brown)}" 
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
                    outp.push [cmd, "[#{i.to_s.color(:white)}] #{cmd.color(:brown)}\n"]
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

    #handy predefined objects
HASH = { 
  :bob => 'b', :mom => 'm', 
  :gods => 0, :devils => 1.0/0} unless defined?(HASH)
ARRAY = HASH.keys unless defined?(ARRAY)
puts "[irbrc] ".color(:darkgreen) + "variables de conveniencia definidas: [HASH, ARRAY]"


#§ require libs

$LOAD_PATH << "#{ENV['HOME']}/bin/lib"
gems=[]
#gems.push :awesome_print => nil
gems.push [
    std_helpers: nil,
    benchmark: lambda{     
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
    bond: lambda{
        begin
            Bond.start
        rescue LoadError => e
            puts "[irbrc] ".color(:red) +  "could not use Bond gem, falling back to irb/completion.\nReason:\n\t#{e.message}\n"
            unless IRB.conf[:LOAD_MODULES].include?('irb/completion')
                IRB.conf[:LOAD_MODULES] << 'irb/completion'
            end
        end
    },
    interactive_editor: nil
]
GEMS=[]
gems.flatten!.each do |h| h.each do |lib,callback|
    begin
        require lib.to_s
        callback.yield unless callback.nil?        
    rescue LoadError => e
        puts "[irbrc] ".color(:red) +  "could not use '#{lib}' gem.\nReason:\n\t#{e.message}\n"
    else
        GEMS.push lib
    end
end;end
puts "[irbrc] ".color(:darkgreen) + "gems cargadas #{GEMS}"


#§ standard IRB config

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
    Readline::HISTORY.to_a.reverse.each do |cmd| 
        if uniq_history.include? cmd
            new_history.push cmd
            uniq_history.delete cmd
        end
    end
    new_history.reverse!
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
    :PROMPT_I => "#{$0}(%m):%03n \001" + "% ".color(:yellow) + "\002", #normal
    :PROMPT_S => nil, #string continue
    :PROMPT_C => "#{$0}(%m):%03n % ", #statement continue
    :RETURN => "%s\n" #format return value
}
IRB.conf[:PROMPT_MODE]=:CUSTOM

alias quit exit
