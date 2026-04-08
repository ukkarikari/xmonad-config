
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
import XMonad.Layout.PerWorkspace
import XMonad.Layout.Grid
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
import XMonad.StackSet as W hiding (workspaces)
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
  , ppOrder = \(ws:l:t:ex) -> [t, l, ws] ++ ex
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


-- ========== WORKSPACES =======
myWorkspaces :: [WorkspaceId]
myWorkspaces = 
  [ "code"
  , "web"
  , "chat"
  , "sys"
  , "notes"
  ]


--  ========= LAYOUTS =========
myLayouts =
  avoidStruts $
    onWorkspace "code"  codeLayouts $
    onWorkspace "sys"   sysLayouts $   
    onWorkspace "chat"   chatLayouts $   
    defaultLayout

codeLayouts =
      magnifiercz' 1.3 $ ResizableThreeColMid 1 (3/100) (3/5) []
  ||| Full

sysLayouts =
      meinKreis
  ||| Grid

chatLayouts =
    magnifiercz 1 (gaps [(L,45),(R,45),(U,5),(D,00)] Accordion )

defaultLayout = noBorders Full

-- myLayouts = avoidStruts $
--  magnifiercz' 1.3 $ ResizableThreeCol 1 (3/100) (3/5) [] -- TODO: if 3 win, do centerMid
--  ||| magnifiercz 1 (gaps [(L,45),(R,45),(U,5),(D,00)] Accordion )
--  ||| noBorders Full
--  ||| meinKreis


--  --------- specific definitions --------- 
meinKreis =
  renamed [CutWordsLeft 10, Replace "circle"] $ 
    gaps [(L,120),(R,200),(U,20),(D,20)] (
      magnifierxy' 1 1 $
        circleEx { cMasterRatio = 4%8
               , cStackRatio = 3%8
               , cMultiplier = 6%7
               , cDelta = 2.2*pi/4
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
  ++workspaceKeybs

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
  , ("M-S-m", sendMessage ToggleStruts)
  ]

utilityKeybs = [
  -- screenshot tools
    ("<Print>", spawn "scrot -f ~/Pictures/Screenshots/%F-%H%M%S.png")
  , ("S-<Print>", spawn "scrot -s -e 'xclip -selection clipboard -t image/png -i $f' -f /var/tmp/%F-%H%M%S.png")
  -- screen lock
  , ("<XF86ScreenSaver>", spawn "xtrlock")
  -- dmenu
  , ("M-p", spawn "dmenu_run -sb '#ffffff' -sf '#000000' -fn Cozette-10")
  ]

miscKeybs = [
  -- TODO change this to be a workspace selector
    ("M-<Tab>", goToSelected def )
  ]

workspaceKeybs = [
    ("M-1", windows $ W.greedyView "code")
  , ("M-S-1", moveAndFollow "code")
  , ("M-2", windows $ W.greedyView "web")
  , ("M-S-2", moveAndFollow "web")
  , ("M-7", windows $ W.greedyView "chat")
  , ("M-S-7", moveAndFollow "chat")
  , ("M-8", windows $ W.greedyView "sys")
  , ("M-S-8", moveAndFollow "sys")
  , ("M-9", windows $ W.greedyView "notes")
  , ("M-S-9", moveAndFollow "notes")
  ]

myRemovedKeys = [
    "M-S-q" --disable default exit
  , "M-p"   --disable default dmenu
  , "M-3", "M-S-3"
  , "M-4", "M-S-4"
  , "M-5", "M-S-5"
  , "M-6", "M-S-6"
  ]

moveAndFollow ws = 
  windows (W.shift ws) >> windows (W.greedyView ws)

-- ++++++++++ CONFIGURATION +++++++++
myConfig dzen = def
  {
    modMask = mod4Mask -- rebind alt to win
  , layoutHook  = myLayouts
  , manageHook  = myManageHook <+> manageDocks <+> manageHook def
  , startupHook = myStartupHook
  , logHook = dynamicLogWithPP (myPP dzen) >> updatePointer (0.5, 0.5) (0, 0)
  , workspaces = myWorkspaces
  , focusFollowsMouse = False
  , terminal  = "urxvt"
  , normalBorderColor = "#888888"
  , focusedBorderColor = "#ffffff"
  }
  `removeKeysP` myRemovedKeys
  `additionalKeysP` myKeybs
