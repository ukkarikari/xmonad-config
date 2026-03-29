import XMonad
import XMonad.Util.EZConfig
import XMonad.Hooks.ManageHelpers
import Data.Ratio

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

-- TO ADD:
-- - [ ] some way to toggle simpleFloat with keybind (instead of being a default)
-- - [ ] keybind to change layout lists. different lists for differnt setups (like 4:3 16:9 vertical etc)
-- - [ ] reading + notes layout


-- 	=== MANAGE HOOK ===
myManageHook :: ManageHook
myManageHook = composeAll
  [ isDialog --> doFloat
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
 ||| Accordion

-- 	=== MAIN ===
main :: IO ()
main = xmonad myConfig

myConfig = def
  { modMask = mod4Mask -- rebind to win
	, layoutHook 	= myLayouts
	, manageHook	= myManageHook <+> manageHook def
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
   	, ("M-<Tab>", goToSelected def)
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
	, ("<XF86ScreenSaver>", spawn "xtrlock")
	-- disables exit
	, ("M-S-q", return ()) ]


