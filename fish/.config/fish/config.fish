# armojidots fish config: prompt + greeting (conf.d/armoji_greeting.fish).
# Put your own aliases, env and tools in conf.d/local.fish (not tracked).
if status is-interactive
    starship init fish | source

    # mark prompt starts (OSC 133) so the terminal can jump between prompts
    function mark_prompt_start --on-event fish_prompt
        echo -en "\e]133;A\e\\"
    end
end
