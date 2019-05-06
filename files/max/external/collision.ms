--dhruva_tools_category_definition@Collision_Maker@dhruva_tools@Tools@

/*HeaderStart******************************************************************************
:Created By:		Kiran Pulicheri ,  Priyabrata Biswal
:Company:		Dhruva Infotech.
:Site:			http://dhruva.com
:E-mail:			author@dhruva.com

:Script Name:		[SCRIPT NAME]

:Purpose:


:History:


:Todo:


:Bugs:


:Tests:


*****************************************************************************HeaderEnd*/
	try (destroyDialog rol_collisionCreator) catch()
	rollout rol_collisionCreator "Collision Creator" width:150 height:220
	(
		
	-- 	//---- UI Part	
			
	-- 	local orientation = false
		radiobuttons cb_prefix "" align:#center width:140 height:16 labels:#("Prefix", "Suffix") columns:2 checked:true		
		edittext prefx_Sufx_txt "Prefix:" text:"c_" pos:[8,24] width:138 height:17 enabled:true
		group "Collison Object Properties:" (
			dropdownList colType pos:[8,65] width:80 height:40 items:#("box", "sphere", "capsule", "convex") 
			checkbox cb_orient "Align" pos:[96,68] width:47 height:15 )
		group "Convex Mesh Properties" (
			spinner spn_vrtCount "VertCount" align:#left width:122 height:16 enabled:false range:[8,32,32] type:#integer)	
		button btn_create "Create" width:140 height:21	
		spinner spnPush "Push" fieldwidth:48 type:#float range:[1.0,100,1.0] pos:[8,169] 
	-- 	edittext cb_offset "Scale " pos:[8,144] width:85 height:17 across:2  
		button btn_increment "+" pos:[101,166] width:20 height:20 across:2
		button btn_decrement "-" pos:[125,166] width:20 height:20 across:2	
		button btn_Export "Export" pos:[8, 192] across:2 width:138
	-- 	button btn_ExpPath ".." pos:[125,192] width:20 height:20
			
		local colTypeItem = 1
	-- 	local fileExpPath = ""
	-- 	//----Functions
	-- 	//---- align the object on Align checked
		fn alignObj colObj tmpObj = 
		(
			centerPivot tmpObj
			centerPivot colObj 
			if cb_orient.state then (colObj.transform = tmpObj.transform)
			else colObj.pos = tmpObj.pos
		)
	-- 	//---- Function to scale the convex object	
		
		fn scaleColObjs up:false = 
		(	
			setCommandPanelTaskMode #create
			local modPush = Push()
			local colObjects = for ii in selection where (matchpattern ii.name pattern:"*c_*" or "*_c") != false collect ii
			addModifier (colObjects) modPush 
			for obj in colObjects do
			(
				if up then (obj.modifiers[1].pushValue = spnPush.value)
				else (obj.modifiers[1].pushValue = -(spnPush.value))
			)
			convertToPoly selection
		)
		
		fn colMeshName obj = 
		(			
			obj.name = if cb_prefix.state == 1 then (uniquename(prefx_Sufx_txt.text+colType.items[colTypeItem]+"_") numDigits:2)
						else (uniquename(colType.items[colTypeItem]+prefx_Sufx_txt.text+"_") numDigits:2)			
		)
		fn makeCollision obj =
		(
			if classof obj == editable_poly then
			(
				local faceList = getFaceSelection obj			
				if faceList.numberSet == 0 then
				(				
					local tmpObjBox = nvpx.CreateBoundingBox obj
					local tmpObjSphere = nvpx.CreateBoundingSphere obj
					local tmpObjCapsule = nvpx.CreateBoundingCapsule obj
					case colTypeItem of(					
						1 : ( 	local colMesh = box width:tmpObjBox.width height:tmpObjBox.height length:tmpObjBox.length
								colMeshName colMesh
								alignObj colMesh tmpObjBox							
							)
						2 : (						
								local colMesh = Sphere radius:tmpObjSphere.radius segs:8
								colMeshName colMesh
								alignObj colMesh tmpObjSphere												
							)
						3 : (						
								local colMesh = capsule radius:tmpObjCapsule.radius height: tmpObjCapsule.height sides:8
								colMeshName colMesh
								alignObj colMesh tmpObjCapsule													
							)
						4: 
							(							
								local convObj = nvpx.CreateBoundingShapeConvex obj spn_vrtCount.value 0.0 0							
								centerPivot convObj
								colMeshName convObj
								convertToPoly convObj
							)
						)
					try( delete #(tmpObjBox,tmpObjSphere,tmpObjCapsule ))catch()
				)
				else if faceList.numberSet >= 2 then
				(
					local tempObjName = uniqueName "colMeshTMP_"
					polyOp.detachFaces obj faceList delete:false asNode:true name:tempObjName
					local colMeshTMP = getNodeByName tempObjName
					local tmpObj1 = nvpx.CreateBoundingCapsule colMeshTMP
					local tmpObjBox = nvpx.CreateBoundingBox (if cb_orient.state then (tmpObj1) else (colMeshTMP))
					local tmpObjSphere = nvpx.CreateBoundingSphere (if cb_orient.state then (tmpObj1) else (colMeshTMP))					
					case colTypeItem of
					(				
						1 : (												
								local colMesh = box width:tmpObjBox.width height:tmpObjBox.height length:tmpObjBox.length
								colMeshName colMesh
								if cb_orient.state then (alignObj colMesh tmpObj1)
									else (alignObj colMesh tmpObjBox)
							)
						2 : (											
								local colMesh = sphere radius:tmpObjSphere.radius segs:8
								colMeshName colMesh
								if cb_orient.state then (alignObj colMesh tmpObj1)
								else (alignObj colMesh tmpObjSphere)
							)	
						3 : (	
								local colMesh = Capsule radius:tmpObj1.radius height:tmpObj1.height sides:8
								colMeshName colMesh 
								alignObj colMesh tmpObj1						
							)
						4:
							(							
								local convObj = nvpx.CreateBoundingShapeConvex colMeshTMP spn_vrtCount.value 0.0 0
								centerPivot convObj
								colMeshName convObj
								convertToPoly convObj							
							)
					)
					try(delete #(tmpObj1,tmpObjBox,colMeshTMP,tmpObjSphere))catch()
				)
				else (messagebox "Select More than one Face")
			)
			else (messagebox "Select an Editable Poly Object")
		)
		fn exportFbxFile =
		(
			if selection[1] != undefined then
			(
				local fileExpPath = getSaveFileName caption:"Export to" types:"fbx (*.fbx)|*.fbx" 			
				if 	fileExpPath != undefined then 
				(
					local curUnits = units.SystemType 
					units.SystemType = #Centimeters
					local versionControl = FbxExportergetParam "FileVersion"
					local fileVer = "FBX200611"				
					FbxExporterSetParam "ASCII" true
					FbxExporterSetParam "ConvertUnit" "cm"
					if versionControl != undefined then (FbxExporterSetParam "FileVersion" fileVer)
					else (FbxExporterSetParam "FileVersion" "FBX201100")
					exportFile fileExpPath #noPrompt selectedOnly:true
					units.SystemType =  curUnits 	
				)				
			)
			else(messagebox "No Object Selected")
		)	
		on cb_prefix changed theState do
		(
			if theState == 1 then 
			(
				prefx_Sufx_txt.caption = "Prefix"
				prefx_Sufx_txt.text = "c_"	
			) 
			else
			(
				prefx_Sufx_txt.caption = "Suffix"
				prefx_Sufx_txt.text = "_c"
			)		
		)
		on colType selected item do
		(		
			colTypeItem = item
			if (item == 4) then
			(
				cb_orient.enabled = false
				spn_vrtCount.enabled = True					
			)
			else
			(
				cb_orient.enabled = True
				spn_vrtCount.enabled = False					
				)	
		)
		on btn_Export pressed do (exportFbxFile())
		on btn_increment pressed do (scaleColObjs up:true)
		on btn_decrement pressed do	(scaleColObjs up:false ) 	
		on btn_create pressed do
		(
			if selection[1] != undefined then (with redraw off makeCollision selection[1])
			else(messagebox "Select an object "	)		
		)
	)
	createDialog rol_collisionCreator
