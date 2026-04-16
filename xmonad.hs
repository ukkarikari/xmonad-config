
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
import XMonad.Layout.ResizableTile
import XMonad.Layout.MultiDishes
import XMonad.Layout.IfMax
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
  spawn "xrdb -merge $HOME/.Xresources"
  dzen <- spawnPipe myDzenCmd
  xmonad
    . docks
    . ewmh
    -- . xmobarProp
    $ myConfig dzen 


-- ========= PRETTY PRINTER and DZEN  =========
-- [main] -> [myConfig] -> [logHook] -> [myPP] -> [dzen2 process] 
-- ============================================
 
-- ---------- dzen command ----------
myDzenCmd :: String
myDzenCmd = 
  "dzen2" 
  ++ " -dock"
  ++ " -ta r"
  ++ " -fn Cozette:bold:size=10"
  ++ " -bg #000000"
  ++ " -fg #ffffff"


-- ---------- pretty printer ----------
myPP h = def
  { ppOutput = hPutStrLn h
  , ppOrder = \(ws:l:t:ex) -> [t, ws] ++ ex
  , ppCurrent = dzenColor "#000000" "#f9f9f9" . wrap " " " "
  , ppHidden = wrap " " " "
  , ppSep = " "
  , ppExtras = [ myCommand, myVolume, mySpace ]
  }

-- just another space
mySpace :: X (Maybe String)
mySpace = do
  return (Just (" "))

-- command segment
myCommand :: X (Maybe String)
myCommand = do
  result <- runProcessWithInput "date" [] ""
  return (Just (init result))

-- volume indicator
myVolume :: X (Maybe String)
myVolume = do
  out <- runProcessWithInput "wpctl" ["get-volume", "@DEFAULT_AUDIO_SINK@"] ""
  let status = if "[MUTED]" `elem` words out
                then "☏"
                else "☎"
  return (Just status)


-- ========== WORKSPACES =======
myWorkspaces :: [WorkspaceId]
myWorkspaces = 
  [ "code"
  , "web"
  , "code2"
  , "chat"
  , "sys"
  ]


--  ========= LAYOUTS =========
myLayouts =
  avoidStruts $
    onWorkspace "code"  codeLayouts $
    onWorkspace "web"  webLayouts $
    onWorkspace "code2"  codeLayouts $
    onWorkspace "sys"   sysLayouts $   
    onWorkspace "chat"   chatLayouts $   
    defaultLayout

codeLayouts =
      noBorders Full
  ||| ( IfMax 2 (magnifiercz' 1.3 ( ResizableTall 1 (3/100) (3/5) [])) $
         IfMax 3 (maximizeVertical ( MultiDishes 2 3 (1/8))) $
           maxMagnifierOff Grid
          )
  

webLayouts =
      Accordion
--  ||| Mirror Accordion

sysLayouts =
      meinKreis
  ||| Grid

chatLayouts =
    magnifiercz 1 (gaps [(L,45),(R,45),(U,5),(D,00)] Accordion )

defaultLayout = 
  noBorders Full

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
  , className =? "dzen2" --> doIgnore -- ignore border
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
  , ("M-=", sendMessage Toggle)
  , ("M-S-=", sendMessage MagnifyMore)
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
  , ("M-p", spawn "dmenu_run -sb '#ffffff' -sf '#000000' -fn Cozette:bold:size=10")
  , ("<XF86AudioLowerVolume>", spawn "wpctl set-volume @DEFAULT_AUDIO_SINK@ 20%-")
  , ("<XF86AudioRaiseVolume>", spawn "wpctl set-volume @DEFAULT_AUDIO_SINK@ 20%+")
  , ("<XF86AudioMute>", spawn "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
  ]

miscKeybs = [
  -- TODO change this to be a workspace selector
    ("M-<Tab>", goToSelected def )
  ]

workspaceKeybs = [
    ("M-1", windows $ W.greedyView "code")
  , ("M-S-1", windows (W.shift "code"))
  , ("M-2", windows $ W.greedyView "web")
  , ("M-S-2", windows (W.shift "web"))
  , ("M-3", windows $ W.greedyView "code2")
  , ("M-S-3", windows (W.shift "code2"))
  , ("M-7", windows $ W.greedyView "chat")
  , ("M-S-7", windows (W.shift "chat"))
  , ("M-8", windows $ W.greedyView "sys")
  , ("M-S-8", windows (W.shift "sys"))
  ]

myRemovedKeys = [
    "M-S-q" --disable default exit
  , "M-p"   --disable default dmenu
  , "M-4", "M-S-4"
  , "M-5", "M-S-5"
  , "M-6", "M-S-6"
  , "M-9", "M-S-9"
  ]

moveAndFollow ws = 
  windows (W.shift ws)


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

