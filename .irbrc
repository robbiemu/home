# encoding: UTF-8
if defined?(Encoding) then
  Encoding.default_external = 'utf-8'
  Encoding.default_internal = 'utf-8'
else
  $KCODE = 'utf-8'
end

$LOAD_PATH << "#{ENV['HOME']}/bin/lib"
require 'IRB_helpers'
IRB.srq.require_from "lib_helpers"
IRB.srq.require(
#    :awesome_print, 
    :benchmark, 
    :bond, 
    :interactive_editor, 
    :std_helpers
)
IRB.notify("para su holgara - #{IRB.srq.loaded.inspect}", :warn)


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
