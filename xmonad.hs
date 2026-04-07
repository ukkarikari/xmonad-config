
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
import XMonad.Layout.Renamed
-- utils
import XMonad.Layout.NoBorders
import XMonad.Layout.Magnifier
import XMonad.Layout.Gaps 
import XMonad.Util.NamedScratchpad
import XMonad.Util.SpawnOnce
import XMonad.Hooks.ManageHelpers
import XMonad.Actions.UpdatePointer
import XMonad.Hooks.InsertPosition
import XMonad.Util.Run ( safeSpawn, spawnPipe, runProcessWithInput )
-- bar
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.StatusBar
import System.IO (hPutStrLn)
import XMonad.Hooks.ManageDocks

-- ++++++++++ MAIN +++++++++++
main :: IO ()
main = do
  dzen <- spawnPipe myDzenCmd
  xmonad
    . docks
    . ewmh
    -- . xmobarProp
    $ myConfig dzen 


-- ========= PRETTY PRINTER and DZEN  =========
-- [main] -> [myConfig] -> [logHook] -> [myPP] -> [dzen2 process] 
-- ============================================
-- https://hackage-content.haskell.org/package/xmonad-contrib-0.18.2/docs/XMonad-Hooks-StatusBar-PP.html
myPP h = def
  { ppOutput = hPutStrLn h
  , ppCurrent = dzenColor "#000000" "#f9f9f9" . wrap " " " "
  , ppHidden = wrap " " " "
  , ppTitle = dzenColor "#000000" "#f9f9f9" . wrap " " " "
  , ppSep = " "
  , ppExtras = [ myCommand ]
  }

myCommand :: X (Maybe String)
myCommand = do
  result <- runProcessWithInput "date" [] ""
  -- result <- runProcessWithInput "tail" ["/sys/class/power_supply/BAT0/capacity"] ""
  return (Just (init result))


myDzenCmd :: String
myDzenCmd = 
  "dzen2" 
  ++ " -dock"
  ++ " -ta r"
  ++ " -fn Cozette:size=10:style=Bold"
  ++ " -bg #000000"

-- ---- new bars experiment ---
-- idea: http://gotmor.googlepages.com/dzen



--  ========= LAYOUTS =========
myLayouts = avoidStruts $
 magnifiercz' 1.3 $ ResizableThreeCol 1 (3/100) (3/5) [] -- TODO: if 3 win, do centerMid
 ||| magnifiercz 1 (gaps [(L,45),(R,45),(U,5),(D,00)] Accordion )
 ||| noBorders Full
 ||| meinKreis


--  --------- specific definitions --------- 
meinKreis =
  renamed [CutWordsLeft 10, Replace "circle"] $ 
    gaps [(L,120),(R,200),(U,20),(D,20)] (
      magnifierxy' 1 1 $
        circle { cMasterRatio = 2%8
               , cStackRatio = 3%8
               , cMultiplier = 6%7
               , cDelta = 1*pi/4
               })


-- ========= STARTUP HOOK =========
myStartupHook = do
  spawnOnce "redshift -r -l manual" 
  mapM_ spawnOnce [
  -- lock xss cmd
    "xss-lock xtrlock"

  -- compositor cmd
    , "pkill picom ; picom --backend glx --fading --fade-delta 2 --config tmp-config"

  -- night light command
  --, "redshift -r -l '14.91:-23.52'"
  
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


-- ++++++++++ CONFIGURATION +++++++++
myConfig dzen = def
  {
    modMask = mod4Mask -- rebind alt to win
  , layoutHook  = myLayouts
  , manageHook  = myManageHook <+> manageDocks <+> manageHook def
  , startupHook = myStartupHook
  , logHook = dynamicLogWithPP (myPP dzen) >> updatePointer (0.5, 0.5) (0, 0) 
  , focusFollowsMouse = False
  , terminal  = "urxvt"
  , normalBorderColor = "#888888"
  , focusedBorderColor = "#ffffff"
  }
  `additionalKeysP` myKeybs ++ [("M-S-q", return ())] -- disable default exit keybind

