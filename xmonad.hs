
-- main
import XMonad
import XMonad.Util.EZConfig
import XMonad.Hooks.EwmhDesktops
import Data.Ratio
--layouts
import XMonad.Layout.ResizableThreeColumns
import XMonad.Layout.Accordion
import XMonad.Layout.CircleEx
import XMonad.Actions.GridSelect
-- utils
import XMonad.Layout.NoBorders
import XMonad.Layout.Magnifier
import XMonad.Layout.Gaps 
import XMonad.Util.NamedScratchpad
import XMonad.Util.SpawnOnce
import XMonad.Hooks.ManageHelpers
import XMonad.Actions.UpdatePointer
import XMonad.Hooks.InsertPosition
-- bar
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.StatusBar


--  ========= MAIN =========
main :: IO ()
main =
  xmonad
    . ewmh
    . xmobarProp
    $ myConfig

-- ++++++++++ CONFIGURATION +++++++++
myConfig = def
  {
    modMask = mod4Mask -- rebind alt to win
  , layoutHook  = myLayouts
  , manageHook  = myManageHook <+> manageHook def
  , startupHook = myStartupHook
  , terminal  = "urxvt"
  , logHook = updatePointer (0.5, 0.5) (0, 0)
  , focusFollowsMouse = False
  , normalBorderColor = "#888888"
  , focusedBorderColor = "#ffffff"
  }
  `additionalKeysP` myKeybs ++ [("M-S-q", return ())] -- disable default exit keybind


--  ========= LAYOUTS =========
myLayouts =
 magnifiercz' 1 $ ResizableThreeCol 1 (3/100) (1/2) [] -- to do: if 3 win, do rtcm
 ||| magnifiercz 1 (gaps [(L,45),(R,45),(U,5),(D,00)] Accordion )
 ||| noBorders Full
 ||| meinKreis


--  --------- specific definitions --------- 
meinKreis =
 gaps [(L,120),(R,200),(U,20),(D,20)] (
    magnifierxy' 1 1 $
      circle { cMasterRatio = 2%8
             , cStackRatio = 3%8
             , cMultiplier = 6%7
             , cDelta = 1*pi/4
             })


-- ========= STARTUP HOOK =========
myStartupHook = 
  mapM_ spawnOnce
  [
  -- lock xss cmd
    "xss-lock xtrlock"
  -- compositor cmd
  , "pkill picom ; picom --backend glx --fading --fade-delta 2 --shadow --config tmp-config"
  -- night light command
  , "redshift -l 14.91:-23.52"
  -- TODO edit the wpp src and change this botch
  -- , "$HOME/.local/bin/wppsnow"
  -- , "sleep 2 ; xdotool search --name \"wpp\" windowlower windowsize 1440 900 windowmove 0 0"
  ]
  

--  ========= MANAGE HOOK =========
myManageHook :: ManageHook
myManageHook = composeAll
  [ isDialog --> doFloat
  , className =? "Peek" --> doFloat
  , className =? "Xmessage" --> doCenterFloat
  , title =? "wpp" --> doIgnore -- ignore wallpaper
  ]
  <+> insertPosition Below Newer


--  ========= KEYBINDS =========
myKeybs = 
  windowKeybs
  ++utilityKeybs
  ++miscKeybs

-- ------------------------------
windowKeybs =
  [ 
  -- increase/decrease slave size
    ("M-z", sendMessage MirrorShrink)
  , ("M-a", sendMessage MirrorExpand)
  -- mafnifier keys
  , ("M-S-=", sendMessage Toggle)
  , ("M-=", sendMessage MagnifyMore)
  , ("M--", sendMessage MagnifyLess)
  -- scratchpad thning
  , ("M-S-0", do 
    withFocused (toggleDynamicNSP "dyn1")
    dynamicNSPAction "dyn1"
  )
  , ("M-0", dynamicNSPAction "dyn1")
  ]

-- ------------------------------ 
utilityKeybs =
  [
  -- screenshot tools
    ("<Print>", spawn "scrot -f ~/Pictures/Screenshots/%F-%H%M%S.png")
  , ("S-<Print>", spawn "scrot -s -e 'xclip -selection clipboard -t image/png -i $f' -f /var/tmp/%F-%H%M%S.png")
  -- scren lock
  , ("<XF86ScreenSaver>", spawn "xtrlock")
  ]

-- ------------------------------ 
miscKeybs =
  [
  -- TODO change this to be a workspace selector
    ("M-<Tab>", goToSelected def )
  ]


-- --------------------------------------------------------

-- == CURRENT REQUIREMENTS!
-- - picom-simple-anims-git (compositor)
-- - xdotool (gambiarra)
-- - redshift (lightness)
-- - xclip + scrot (clipboard)
-- - xss-lock + xtrlock (lockscreen)

-- TO ADD:
-- - [ ] some way to toggle simpleFloat with keybind (instead of being a default)
-- - [ ] keybind to change layout lists. different lists for differnt setups (like 4:3 16:9 vertical etc)
-- - [x] reading + notes layout
-- - [ ] make proper compositor config 
-- - [ ] fix wallpaper code 
-- - [ ] add xresources?
-- - [ ] grid layout with custom keybind to toggle magnifier
