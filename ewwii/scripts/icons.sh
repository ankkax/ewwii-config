#!/bin/bash
# icons.sh -- exact Omarchy Nerd Font glyphs (codepoints taken from Omarchy's
# waybar config). Source this from other scripts:  . "$DIR/icons.sh"

# workspaces
I_WS_ACTIVE=$'\U000f14fb'   # md-square_rounded

# cpu (Omarchy uses the md-memory glyph for cpu)
I_CPU=$'\U000f061a'

# audio
I_VOL_OFF=$'\uf026'         # fa-volume_off
I_VOL_LOW=$'\uf027'         # fa-volume_low
I_VOL_UP=$'\uf028'          # fa-volume_up
I_VOL_MUTE=$'\ueee8'        # fa-volume_xmark
I_VOL_HEADPHONES=$'\U000f02cb'  # fa-headphones

# bluetooth
I_BT=$'\U000f00af'              # fa-bluetooth_b
I_BT_CONNECTED=$'\U000f00b1' # md-bluetooth_connect
I_BT_OFF=$'\U000f00b2'      # md-bluetooth_off

# network (index 1..4 = signal strength)
I_WIFI=( "" \
  $'\U000f091f' $'\U000f0922' $'\U000f0925' $'\U000f0928' )
I_WIFI_OFF=$'\U000f092e'    # md-wifi_strength_off_outline
I_ETH=$'\U000f0200'         # md-ethernet (wired link)

# battery (index 1..10 = capacity)
I_BAT_DIS=( "" \
  $'\U000f007a' $'\U000f007b' $'\U000f007c' $'\U000f007d' $'\U000f007e' \
  $'\U000f007f' $'\U000f0080' $'\U000f0081' $'\U000f0082' $'\U000f0079' )
I_BAT_CHG=( "" \
  $'\U000f089c' $'\U000f0086' $'\U000f0087' $'\U000f0088' $'\U000f089d' \
  $'\U000f0089' $'\U000f089e' $'\U000f008a' $'\U000f008b' $'\U000f0085' )
I_PLUG=$'\uf1e6'            # fa-plug

# misc
I_CHEV=$'\uf053'            # fa-chevron_left (tray expander)
I_WEATHER=$'\U000f0595'     # md-weather_partly_cloudy (fallback)
I_CLOSE=$'\uf00d'           # fa-times (pop-up panel close)

# Omarchy quattro bar widgets ------------------------------------------------
# Menu uses the Arch Linux logo (U+F303) drawn from JetBrainsMono Nerd Font;
# OXWM has no icon font, so Omarchy's own glyph (omarchy.ttf U+E900) is replaced.
I_MENU=$'\uf303'            # nf-linux-archlinux  (Arch logo)
I_UPDATE=$'\uf021'          # fa-refresh          (pending updates)
I_BRIGHT=$'\U000f00de'      # md-brightness       (display / monitor)
I_MIC=$'\U000f036c'         # md-microphone
I_MIC_OFF=$'\U000f036d'     # md-microphone_off

# now playing (cliamp) --------------------------------------------------------
I_PLAY=$'\uf04b'            # fa-play
I_PAUSE=$'\uf04c'           # fa-pause
I_STOP=$'\uf04d'            # fa-stop
