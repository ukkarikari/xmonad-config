
import Data.Ratio
import System.IO (hPutStrLn)
import XMonad
import XMonad.Actions.GridSelect
import XMonad.Actions.UpdatePointer
import XMonad.Actions.WindowBringer
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.InsertPosition
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.StatusBar
import XMonad.Layout.Accordion
import XMonad.Layout.CircleEx
import XMonad.Layout.Gaps
import XMonad.Layout.Grid
import XMonad.Layout.IfMax
import XMonad.Layout.Magnifier
import XMonad.Layout.MultiDishes
import XMonad.Layout.NoBorders
import XMonad.Layout.PerWorkspace 
import XMonad.Layout.Renamed
import XMonad.Layout.ResizableThreeColumns
import XMonad.Layout.ResizableTile
import XMonad.Layout.StackTile
import XMonad.Layout.Tabbed
import XMonad.Layout.SimpleFloat
import qualified XMonad.StackSet as W
import XMonad.Util.EZConfig
import XMonad.Util.NamedScratchpad
import XMonad.Util.Run (runProcessWithInput, safeSpawn, spawnPipe)
import XMonad.Util.SpawnOnce
import XMonad.Prompt
import XMonad.Prompt.Shell
import XMonad.Prompt.Pass
import XMonad.Prompt.Workspace
import Config.GridSelect


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
myPP h =
  def
    { ppOutput = hPutStrLn h,
      ppOrder = \(ws : l : t : ex) -> [t, ws] ++ ex,
      ppCurrent = dzenColor "#000000" "#f9f9f9" . wrap " " " ",
      ppHidden = wrap " " " ",
      ppSep = " ",
      ppExtras = [myCommand, myVolume, mySpace]
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
  let status =
        if "[MUTED]" `elem` words out
          then "☏"
          else "☎"
  return (Just status)

    -- ========== WORKSPACES =======
myWorkspaces :: [WorkspaceId]
myWorkspaces =
  [ "code",
    "web",
    "code_alt",
    "chat",
    "sys"
  ]

--  ========= LAYOUTS =========
myLayouts =
  avoidStruts $
    onWorkspaces ["code", "code_alt"] codeLayouts $
    onWorkspace "web" webLayouts $
    onWorkspace "sys" sysLayouts $
    onWorkspace "chat" chatLayouts 
    defaultLayout

codeLayouts =
  noBorders Full
    ||| ( IfMax 2 (magnifiercz' 1.3 (ResizableTall 1 (3 / 100) (3 / 5) [])) $
            IfMax 3 (maximizeVertical (MultiDishes 2 3 (1 / 8))) $
              maxMagnifierOff Grid
        )

webLayouts =
    noBorders (tabbedBottom shrinkText myTabTheme) 
    ||| simpleFloat

sysLayouts =
  meinKreis
  ||| maxMagnifierOff Grid

chatLayouts =
  maxMagnifierOff ( StackTile 1 (3/100) (8/9) )

defaultLayout =
  noBorders Full

--  --------- specific definitions ---------
meinKreis =
  renamed [CutWordsLeft 10, Replace "circle"] $
    gaps
      [(L, 120), (R, 200), (U, 20), (D, 20)]
      ( magnifierxy' 1 1 $
          circleEx
            { cMasterRatio = 4 % 8,
              cStackRatio = 3 % 8,
              cMultiplier = 6 % 7,
              cDelta = 2.2 * pi / 4
            }
      )

myTabTheme :: Theme
myTabTheme = def
  { fontName            = "Cozette:bold:size=12"
  , activeColor         = "#ffffff"
  , inactiveColor       = "#000000"
  , activeBorderColor   = "#ffffff"
  , inactiveBorderColor = "#222222"
  , activeTextColor     = "#000000"
  , inactiveTextColor   = "#666666"
  , decoHeight          = 12
  }

-- ========= STARTUP HOOK =========
myStartupHook = do
  spawnOnce "redshift -r -l manual"
  mapM_
    spawnOnce
    [ -- lock xss cmd
      "xss-lock xtrlock",
      -- compositor cmd
      "pkill picom ; picom --backend glx --fading --fade-delta 2 --config $HOME/.config/picom/picom-config"
      --    TODO edit the wpp src and change this botch
      -- , "$HOME/.local/bin/wppsnow"
      -- , "sleep 2 ; xdotool search --name \"wpp\" windowlower windowsize 1440 900 windowmove 0 0"
    ]

--  ========= MANAGE HOOK =========
myManageHook :: ManageHook
myManageHook =
  composeAll
    [ isDialog --> doFloat,
      className =? "Peek" --> doFloat,
      className =? "Xmessage" --> doCenterFloat,
      className =? "dzen2" --> doIgnore, -- ignore border
      title =? "wpp" --> doIgnore -- ignore wallpaper
    ]
    <+> insertPosition Below Newer

--  ========= KEYBINDS =========
myKeybs =
  windowKeybs
    ++ utilityKeybs
    ++ miscKeybs
    ++ workspaceKeybs

-- ------------------------------
windowKeybs =
  [ -- increase/decrease slave size
    ("M-z", sendMessage MirrorShrink),
    ("M-a", sendMessage MirrorExpand),
    -- mafnifier keys
    ("M-=", sendMessage Toggle),
    ("M-S-=", sendMessage MagnifyMore),
    ("M--", sendMessage MagnifyLess),
    -- toggle dock
    ("M-S-m", sendMessage ToggleStruts)
  ]

utilityKeybs =
  [ -- screenshot tools
    ("<Print>", spawn "scrot -f ~/Pictures/Screenshots/%F-%H%M%S.png"),
    ("S-<Print>", spawn "scrot -s -e 'xclip -selection clipboard -t image/png -i $f' -f /var/tmp/%F-%H%M%S.png"),
    -- screen lock
    ("<XF86ScreenSaver>", spawn "xtrlock"),
    -- dmenu
    ("M-p", spawn "dmenu_run -sb '#ffffff' -sf '#000000' -fn Cozette:bold:size=10"),
    ("<XF86AudioLowerVolume>", spawn "wpctl set-volume @DEFAULT_AUDIO_SINK@ 20%-"),
    ("<XF86AudioRaiseVolume>", spawn "wpctl set-volume @DEFAULT_AUDIO_SINK@ 20%+"),
    ("<XF86AudioMute>", spawn "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
    ("M-g", passPrompt def)
  ]

miscKeybs =
  [ -- TODO change this to be a workspace selector
    ("M-<Tab>", myWorkspaceSelector myGSConfig)
  , ("M-S-<Tab>", bringSelected def)
  ]

workspaceKeybs =
  [
--  ("M-1", windows $ W.greedyView "code"),
    ("M-S-1", windows (W.shift "code")),
--    ("M-2", windows $ W.greedyView "web"),
    ("M-S-2", windows (W.shift "web")),
--    ("M-3", windows $ W.greedyView "code_alt"),
    ("M-S-3", windows (W.shift "code_alt")),
--    ("M-7", windows $ W.greedyView "chat"),
    ("M-S-7", windows (W.shift "chat")),
--    ("M-8", windows $ W.greedyView "sys"),
    ("M-S-8", windows (W.shift "sys"))
  ]

myRemovedKeys =
  [ "M-S-q", -- disable default exit
    "M-p", -- disable default dmenu
    "M-1",
    "M-2",
    "M-3",
    "M-7",
    "M-8",
    "M-4",
    "M-S-4",
    "M-5",
    "M-S-5",
    "M-6",
    "M-S-6",
    "M-9",
    "M-S-9"
  ]

moveAndFollow ws =
  windows (W.shift ws)

-- ++++++++++ CONFIGURATION +++++++++
myConfig dzen =
  def
    { modMask = mod4Mask, -- rebind alt to win
      layoutHook = myLayouts,
      manageHook = myManageHook <+> manageDocks <+> manageHook def,
      startupHook = myStartupHook,
      logHook = dynamicLogWithPP (myPP dzen) >> updatePointer (0.5, 0.5) (0, 0),
      workspaces = myWorkspaces,
      focusFollowsMouse = False,
      terminal = "urxvt",
      normalBorderColor = "#888888",
      focusedBorderColor = "#ffffff"
    }
    `removeKeysP` myRemovedKeys
    `additionalKeysP` myKeybs
