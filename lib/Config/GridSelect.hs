module Config.GridSelect 
  ( myWorkspaceSelector 
  , myGSConfig
  ) where

import XMonad
import XMonad.Actions.GridSelect
import qualified XMonad.StackSet as W

myWorkspaceSelector :: GSConfig (WorkspaceId, Bool) -> X ()
myWorkspaceSelector conf = do
  ws <- gets (W.workspaces . windowset)

  let entries =
        [ (W.tag w, (W.tag w, isNothing w))
        | w <- ws
        ]
      isNothing w = W.stack w == Nothing

  gridselect conf entries
    >>= flip whenJust (\(name, _) -> windows (W.greedyView name))


myColorizer :: (WorkspaceId, Bool) -> Bool -> X (String, String)
myColorizer (_, empty) active =
  return $
    case (active, empty) of
      (True, _)      -> ("#ffffff", "#000000")  -- selected
      (False, True)  -> ("#222222", "#666666")  -- empty workspace
      (False, False) -> ("#222222", "#ffffff")  -- non-empty workspace

myGSConfig :: GSConfig (WorkspaceId, Bool)
myGSConfig = def
  { gs_cellheight = 50
  , gs_cellwidth  = 180
  , gs_cellpadding = 10
  , gs_font       = "xft:Terminus:size=11"
  , gs_colorizer  = myColorizer
  }
