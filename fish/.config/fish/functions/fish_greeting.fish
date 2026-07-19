function fish_greeting
    # sidebars are narrow — they get a mini greeting (SIDEBAR set by sidebar.sh);
    # the width check catches any other skinny terminal
    if set -q SIDEBAR; or test (tput cols 2>/dev/null; or echo 80) -lt 80
        set_color green
        echo "HI ARMOJI ▪"
        set_color normal
    else
        fastfetch
    end
end
