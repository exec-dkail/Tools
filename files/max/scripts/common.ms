--Mesh Opertaions
function SetBackFaceCullOn =
(
	if selection.count > 0 do
	(
		for obj in selection where superClassOf obj == GeometryClass do
		(
			obj.backfacecull = on
		)
	)
)
function RemoveDeadIsoVertices =
(
	for obj in selection where superClassOf obj == GeometryClass and classOf obj == Editable_Poly do
	(
		polyop.deleteIsoVerts obj
	)
)
function ListObjectWithZeroFaces = 
(
	missingFaceGeo = #()
	for obj in objects where superClassOf obj == GeometryClass and classOf obj == Editable_Poly and classOf obj == Editable_Poly do
	(
		if (polyop.getNumFaces obj) == 0 then
		(
			AppendIfUnique missingFaceGeo obj.name
		)
	)
	return missingFaceGeo
)
function ResetXForms flip =
(
	if selection.count > 0 do
	(
		for obj in selection where superClassOf obj == GeometryClass do
		(
			if flip == true then
			(
				normalMod = NormalModifier()
				normalMod.flip = on
				ResetXForm obj
				AddModifier obj normalMod
				ConvertTo obj Editable_Poly
			)
			else
			(
				ResetXForm obj
				ConvertTo obj Editable_Poly
			)
		)
	)			
)
/*
function SelectFacesWithSameSmoothing obj =
(
	local smoothGrp = 0 
	local faceList = #()
	if  (polyop.getFaceSelection obj).numberSet == 1 do
	(
		smoothGrp = polyop.getFaceSmoothGroup obj (polyop.getFaceSelection obj as array)[1]
	)
	if smoothGrp != 0 do
	(
		for i = 1 to (polyop.getNumFaces obj) do 
		(
			if polyop.getFaceSmoothGroup obj i == smoothGrp do 
			(
				AppendIfUnique faceList i
			)
		)
		polyop.setFaceSelection obj faceList
		update obj
	)
)
*/
function SelectSpecialAdjacentFaces obj nVert sGNum = 
(
	faceList = #()
	for v in nVert do
	(
		tempFace = (polyop.getFacesUsingVert obj v) as array
		for j = 1 to tempFace.count do
		(
			if sGNum == (polyop.getFaceSmoothGroup obj tempFace[j]) do
			(
				appendIfUnique facelist tempFace[j]
			)
		)
	)
	return faceList
)
function IterateToNextVertex obj faceList =
(
	unionEdge = #{}
	intersectingEdges = #{}
	
	for f in faceList do Join unionEdge (polyop.getEdgesUsingFace obj f)
	for i = 1 to (faceList as array).count do
	(
		for j = 1 to (faceList as array).count do
		(
			if ((polyop.getEdgesUsingFace obj (faceList as array)[i]) * (polyop.getEdgesUsingFace obj (faceList as array)[j])).numberSet == 1 do
			(
				Join intersectingEdges ((polyop.getEdgesUsingFace obj (faceList as array)[i]) * (polyop.getEdgesUsingFace obj (faceList as array)[j]))
			)
		)
	)
	nxtEdge = (unionEdge - intersectingEdges)
	nxtVerts = polyop.getVertsUsingEdge $ nxtEdge
	return nxtVerts
)
function SelectNonSmoothingFaces =
(
	errorObj = #()
	for obj in objects where classOf obj == Editable_Poly do
	(
		nonSmoothingFaces = #()
		for inc = 1 to (polyop.getNumFaces obj) do
		(
			if (polyop.getFaceSmoothGroup obj inc) == 0 do
			(
				AppendIfUnique nonSmoothingFaces inc
				AppendIfUnique errorObj obj
			)
		)
		if not (nonSmoothingFaces as bitArray).isEmpty do
		(
			polyop.setFaceSelection obj #None	
			polyop.setFaceSelection obj (nonSmoothingFaces as bitarray)		
		)
	)
	return errorObj	
)
fn GetMultipleSmoothing = 
(
	smoothingGroupIDs = #()
	errorObj = #()
	for i = 0 to 32 do
	(
		AppendIfUnique smoothingGroupIDs (2^i)
	)
	for obj in objects where classOf obj == Editable_Poly do
	(
		nonSmoothingFaces = #()
		for inc = 1 to (polyop.getNumFaces obj) do
		(
			if (findItem smoothingGroupIDs (polyop.getFaceSmoothGroup obj inc)) == 0 and (polyop.getFaceSmoothGroup obj inc) != 0 do
			(
				AppendIfUnique nonSmoothingFaces inc
				AppendIfUnique errorObj obj				
			)
			if not (nonSmoothingFaces as bitArray).isEmpty do
			(
				polyop.setFaceSelection obj #None	
				polyop.setFaceSelection obj (nonSmoothingFaces as bitarray)
			)
		)
	)
	return errorObj
)
function GetNonPolyFaces =
(
	errorObj = #()
	for obj in objects where classOf obj == Editable_Poly do
	(
		getNGon = #()
		for faces = 1 to (polyop.getNumFaces obj) do
		(
			if (polyop.getFaceDeg obj faces) > 4 do
			(
				AppendIfUnique getNGon faces
				AppendIfUnique errorObj obj
			)
		)	
		if not (getNGon as bitArray).isEmpty do
		(
			polyop.setFaceSelection obj #None
			polyop.setFaceSelection obj getNGon
		)
	)
	return errorObj
)
function SetWireColor = 
(
	for obj in objects where superClassOf obj == GeometryClass do
	(
		obj.wirecolor = color 115 115 115
	)
	for indx = 0 to 6 do
	(
		wirecolor = color (Random 10 255) (Random 10 255) (Random 10 255)
		for obj in (execute("$*LOD0"+(indx as string))) where superClassOf obj == GeometryClass and obj != undefined do
		(
			obj.wirecolor = wirecolor
		)
	)
	for indx = 0 to 6 do
	(
		wirecolor = color (Random 10 255) (Random 10 255) (Random 10 255)
		for obj in (execute("$*COL0"+(indx as string))) where superClassOf obj == GeometryClass and obj != undefined do
		(
			obj.wirecolor = wirecolor
		)
	)	
	displayColor.shaded = #object
)
function RemoveCollisionMaterials = 
(
	for indx = 0 to 6 do
	(
		for obj in (execute("$*COL0"+(indx as string))) where superClassOf obj == GeometryClass and obj != undefined do
		(
			obj.material = undefined
		)
	)	
)
--Pivot Opertaions
function SetPivot location =
(
	case location of 
	(
		"World" :
		(
			if selection.count > 0 do
			(
				for obj in selection where superClassOf obj == GeometryClass do
				(
					obj.pivot = [0,0,0]
				)
			)
		)
		"Lowest" :
		(
			if selection.count > 0 do
			(
				for obj in selection where superClassOf obj == GeometryClass do
				(
					obj.pivot = obj.center
					obj.pivot.z -= (obj.max-obj.min).z/2
				)
			)
		)
		"Center" :
		(
			if selection.count > 0 do
			(
				for obj in selection where superClassOf obj == GeometryClass  do
				(
					obj.pivot = obj.center
				)
			)
		)
		"Local" :
		(
			if selection.count == 1 do
			(
				for obj in selection where superClassOf obj == GeometryClass  do
				(
					if subObjectLevel == 4 do
					(
						faceLocalDirection = inverse ((matrixFromNormal (polyop.getFaceNormal obj (polyop.getFaceSelection obj as array)[1]) * obj.transform ) as quat)
						obj.pivot = (polyop.getFaceCenter obj (polyop.getFaceSelection obj as array)[1])
						on animate off in coordsys local obj.rotation *= faceLocalDirection
						obj.objectOffsetRot *= faceLocalDirection
						obj.objectOffsetPos *= faceLocalDirection
					)
				)
			)
		)
		"Default" :
		(
			print "No Default Function"
		)
	)
)
--Materials
fn CheckMaterialID =
(
	matID = #()	
	for obj in selection where superClassOf obj == GeometryClass do
	(
		for face = 1 to (polyop.getNumFaces obj) do
		(
			appendIfUnique matID (polyop.getFaceMatID obj face)
		)
	)
	sort matID
	return matID
)
fn ListViewMaterialID matID =
(
	validID = ""
	invalidID = ""
	mat = selection[1].material.materialIDList
	for each in mat do
	(
		if (findItem matID each) == 0 then
		(
			invalidID += "ID : " + each as string + "\n"
		)
		else
		(
			validID += "ID : " + each as string + "\n"
		)
	)
	--formatting String.
	str = "VALID MATERIALS\n"
	str += "-----------------------\n"
	str += validID
	str += "-----------------------\n"
	str += "INVALID MATERIALS\n"
	str += "-----------------------\n"
	str += invalidID	
	return str
)
--UV Opertaions
function SelectFaceByMaterialID obj id =
(
	if obj != undefined do
	(
		obj.selectByMaterial id
	)
)
function ClearUnusedChannels obj val =
(
	numMap = polyop.getNumMaps obj			
	for inc = numMap to (val+1) by -1 do
	(
		channelInfo.clearChannel obj inc
	)
	ConvertTo obj Editable_Poly
)
function TransformUV direction val = 
(
	uvMod = ModPanel.getCurrentObject()
	if classOf uvMod == Unwrap_UVW do
	(
		case direction of
		(
			"UP" :
			(
				uvMod.MoveSelected [0,val,0]
			)
			"DOWN" :
			(
				uvMod.MoveSelected [0,-val,0]
			)
			"LEFT" :
			(
				uvMod.MoveSelected [-val,0,0]
			)
			"RIGHT" :
			(
				uvMod.MoveSelected [val,0,0]
			)
		)
	)
)
function ScaleUVByPercentage val = 
(
	uvMod = ModPanel.getCurrentObject()
	if classOf uvMod == Unwrap_UVW do
	(
		uvMod.scaleSelectedCenter val 0
	)
)
--Misc
function CopyObjects = 
(
	if selection.count > 0 do
	(
		objectNodes = #()
		for obj in selection do
		(
			AppendIfUnique objectNodes obj
		)
		if doesFileExist (PathConfig.AppendPath (getDir #maxstart) "_CopiedGeo") then
		(
			File = dotNetClass "System.IO.File"
			File.Delete (PathConfig.AppendPath (getDir #maxstart) "_CopiedGeo")
			saveNodes objectNodes (PathConfig.AppendPath (getDir #maxstart) "_CopiedGeo") saveAsVersion:2014 quiet:true
		)
		else
		(
			saveNodes objectNodes (PathConfig.AppendPath (getDir #maxstart) "_CopiedGeo") saveAsVersion:2014 quiet:true
		)
	)
)
function PasteObjects =
(
	if doesFileExist (PathConfig.AppendPath (getDir #maxstart) "_CopiedGeo.max") then
	(
		mergeMAXFile (PathConfig.AppendPath (getDir #maxstart) "_CopiedGeo.max") #mergeDups #autoRenameDups #useSceneMtlDups #alwaysReparent quiet:true
	)
)
