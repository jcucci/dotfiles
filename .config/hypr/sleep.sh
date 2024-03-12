swayidle -w timeout 300 "swaylock --image '/home/jcucci/pictures/backgrounds/gray_textured_curvy.jpg' --show-failed-attempts" \
    timeout 600 "hyprctl dispatch dpms off" \
    resume "hyprctl dispatch dpms on" \
    timeout 900 "systemctl suspend" \
    before-sleep "swaylock --image '/home/jcucci/pictures/backgrounds/gray_textured_curvy.jpg' --show-failed-attempts" &
