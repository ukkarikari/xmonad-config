
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
import XMonad.Util.Run (spawnPipe)
import System.IO (hPutStrLn)
import XMonad.Hooks.ManageDocks


-- ++++++++++ MAIN +++++++++++
main :: IO ()
main = do
  dzen <- spawnPipe myDzenCmd -- (this is like 'stdin | myDzenCmd') its kind of an "entry point"
  xmonad
    . docks
    . ewmh
    -- . xmobarProp
    $ myConfig dzen 


-- ++++++++++ CONFIGURATION +++++++++
-- myConfig is type "XConfig Layout". by adding dzen we are doing:
--     myConfig :: Handle -> XConfig Layout 
-- muConfig is now a funton that takes a Hanlde (dzen) and returns a XConfig Layout
--
myConfig dzen = def
  {
    modMask = mod4Mask -- rebind alt to win
  , layoutHook  = myLayouts
  , manageHook  = myManageHook <+> manageDocks <+> manageHook def
  , startupHook = myStartupHook
  , terminal  = "urxvt"
-- in here, logHook creates a String based on the current xmonad state
-- ppOutput
  , logHook = dynamicLogWithPP (myPP dzen) >> updatePointer (0.5, 0.5) (0, 0) 
  , focusFollowsMouse = False
  , normalBorderColor = "#888888"
  , focusedBorderColor = "#ffffff"
  }
  `additionalKeysP` myKeybs ++ [("M-S-q", return ())] -- disable default exit keybind



--  ========= LAYOUTS =========
myLayouts =  
 avoidStruts $ magnifiercz' 1.3 $ ResizableThreeCol 1 (3/100) (3/5) [] -- TODO: if 3 win, do centerMid
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


-- ========= PRETTY PRINTER and DZEN  =========
myPP h = def
  {
  -- ppOutput = hPutStrLn h --output will be argument as string
  ppOutput = \s -> hPutStrLn h ("I AM LEARNING " ++ s)
  } 


myDzenCmd :: String
myDzenCmd = 
  "dzen2" 
  ++ " -dock"
  ++ " -ta l"
  ++ " -fn PixelCarnageMonoTT-9"
  ++ " -bg #000000"


-- ========= STARTUP HOOK =========
myStartupHook = 
  mapM_ spawnOnce [
  -- lock xss cmd
    "xss-lock xtrlock"

  -- compositor cmd
  , "pkill picom ; picom --backend glx --fading --fade-delta 2 --config tmp-config"

  -- night light command
  , "redshift -l 14.91:-23.52"
  
  --    TODO edit the wpp src and change this botch
  -- , "$HOME/.local/bin/wppsnow"
  -- , "sleep 2 ; xdotool search --name \"wpp\" windowlower windowsize 1440 900 windowmove 0 0"
  ]
  

--  ========= MANAGE HOOK =========
myManageHook :: ManageHook
myManageHook = composeAll
  [ isDialog --> doFloat
  , className =? "Peek" --> doFloat
  , className =? "Xmessage" --> doCenterFloat
  , className =? "dzen2" --> doIgnore
  , title =? "wpp" --> doIgnore -- ignore wallpaper
  ]
  <+> insertPosition Below Newer


--  ========= KEYBINDS =========
myKeybs = 
  windowKeybs
  ++utilityKeybs
  ++miscKeybs

-- ------------------------------
windowKeybs = [ 
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
    dynamicNSPAction "dyn1")
  , ("M-0", dynamicNSPAction "dyn1")
  -- toggle dock
  , ("M-m", sendMessage ToggleStruts)
  ]

utilityKeybs = [
  -- screenshot tools
    ("<Print>", spawn "scrot -f ~/Pictures/Screenshots/%F-%H%M%S.png")
  , ("S-<Print>", spawn "scrot -s -e 'xclip -selection clipboard -t image/png -i $f' -f /var/tmp/%F-%H%M%S.png")
  -- scren lock
  , ("<XF86ScreenSaver>", spawn "xtrlock")
  ]

miscKeybs = [
  -- TODO change this to be a workspace selector
    ("M-<Tab>", goToSelected def )
  ]

