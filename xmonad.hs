import XMonad
import XMonad.Util.EZConfig
import XMonad.Hooks.ManageHelpers
import Data.Ratio
import XMonad.Hooks.EwmhDesktops

import XMonad.Actions.UpdatePointer
import XMonad.Actions.GridSelect

import XMonad.Hooks.InsertPosition

import XMonad.Layout.Grid
import XMonad.Layout.ResizableTile
import XMonad.Layout.Tabbed
import XMonad.Layout.Accordion
import XMonad.Layout.NoBorders
import XMonad.Layout.Magnifier
import XMonad.Layout.Roledex
import XMonad.Layout.CircleEx
import XMonad.Layout.Spiral hiding (CW)
import XMonad.Layout.Dishes
import XMonad.Layout.Reflect
import XMonad.Layout.OneBig
import XMonad.Layout.Monitor
import XMonad.Layout.SimpleFloat
import XMonad.Layout.Square
import XMonad.Layout.FixedAspectRatio
import XMonad.Layout.ResizeScreen
import XMonad.Layout.Gaps
import XMonad.Layout.SubLayouts
import XMonad.Layout.WindowNavigation

import XMonad.Util.NamedScratchpad
import XMonad.Util.SpawnOnce

-- == CURRENT REQUIREMENTS!
-- - picom-simple-anims-git (compositor)
-- - xdotool (gambiarra)
-- - redshift (lightness)
-- - xclip + scrot (clipboard)
-- - xss-lock + xtrlock (lockscreen)

-- TO ADD:
-- - [ ] some way to toggle simpleFloat with keybind (instead of being a default)
-- - [ ] keybind to change layout lists. different lists for differnt setups (like 4:3 16:9 vertical etc)
-- - [ ] reading + notes layout
-- - [ ] make proper compositor config 
-- - [ ] make proper redshift config 
-- - [ ] fix wallpaper code 
-- - [ ] add xresources?

-- 	=== MANAGE HOOK ===
myManageHook :: ManageHook
myManageHook = composeAll
  [ isDialog --> doFloat
  , className =? "Peek" --> doFloat
  , className =? "Xmessage" --> doCenterFloat
  , title =? "wpp" --> doIgnore -- ignore wallpaper
  ]
  <+> insertPosition Below Newer

-- 	=== LAYOUTS ===
myLayouts =
 magnifiercz' 1 ( spiral 1 )
 ||| (gaps [(L,120),(R,200)] $
     magnifierxy' 1 1 $
       circle { cMasterRatio = 6%8
              , cStackRatio = 5%8
              , cDelta = 1*pi/4
              , cMultiplier = 5%6
              })
 ||| noBorders Full
 ||| magnifiercz 1 (gaps [(L,100),(R,100),(U,20),(D,20)] $ Accordion )
-- ||| magnifiercz 1 (gaps [(L,25),(R,300),(U,10),(D,100)] $ Roledex )

--	=== STARTUP HOOK ===
myStartupHook = do
  spawnOnce "redshift -l 14.91:-23.52" -- light adjustment (set to praia cape verde)
  spawnOnce "xss-lock xtrlock"
  spawnOnce "$HOME/.local/bin/wppsnow" -- TODO change this!
  spawnOnce "sleep 2 ; xdotool search --name \"wpp\" windowlower windowsize 1440 900 windowmove 0 0" --TODO change this!
  spawnOnce "pkill picom; picom --backend glx --vsync --animations --animation-window-mass 0.2 --animation-stiffness-in-tag 650 --animation-dampening 10 --animation-for-open-window none" --TODO change this!

-- 	=== MAIN ===
main :: IO ()
main = xmonad
       . ewmhFullscreen
       . ewmh
       $ myConfig

myConfig = def
  { modMask = mod4Mask -- rebind to win
	, layoutHook 	= myLayouts
	, manageHook	= myManageHook <+> manageHook def
	, startupHook	= myStartupHook
	, terminal	= "urxvt"
	, logHook 	= updatePointer (0.5, 0.5) (0, 0)
	, focusFollowsMouse = False
	}
	`additionalKeysP`
	[
	-- increase decrease slave size
	  ("M-z", sendMessage MirrorShrink)
	, ("M-a", sendMessage MirrorExpand)

	-- printing utilities
	, ("<Print>", spawn "scrot -f ~/Pictures/Screenshots/%F-%H%M%S.png")
	, ("S-<Print>", spawn
	"scrot -s -e 'xclip -selection clipboard -t image/png -i $f' -f /var/tmp/%F-%H%M%S.png")
	-- window selector
   	, ("M-<Tab>", goToSelected def )
   	-- scratchpad thning
   	, ("M-S-0", do 
		withFocused (toggleDynamicNSP "dyn1")
		dynamicNSPAction "dyn1"
	)
   	, ("M-0", dynamicNSPAction "dyn1")
	-- magnification setup
	, ("M-S-=", sendMessage Toggle)
	, ("M-=", sendMessage MagnifyMore)
	, ("M--", sendMessage MagnifyLess)
	-- locker
	, ("<XF86ScreenSaver>", spawn "xtrlock")
	-- disables exit
	, ("M-S-q", return ()) ]

