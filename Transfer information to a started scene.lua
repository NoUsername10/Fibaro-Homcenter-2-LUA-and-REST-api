-- Transfer information to a started scene
local sId = __fibaroSceneId
	fibaro:startScene(sceneID, {sId}) -- Multiple argumnets possible


-- The started scene, retrevie the information in the started scene
local scene_arg = fibaro:args()
local scene_ID = scene_arg[1] -- multiple arguments possible
	fibaro:debug("Called by scene ID: "..scene_ID)
