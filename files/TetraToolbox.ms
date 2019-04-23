/*
Tetra Toolbox v1.0
-------------------------------------
Common Mesh & UV Operation
Last Date Modified : 16-10-2018
-------------------------------------
Mesh 
	+ Backface Cull
	+ Reset XForm
	+ Reset XForm Mirrored
	+ Remove Dead/Iso Vertices
	+ Check NGons
	+ Select Non Smoothing Faces
	+ Remove Objects with Empty Faces
	+ Apply LOD Wirecolor
	+ Remove Collision Materials

Pivot
	+ Pivot to World
	+ Pivot To Center
	+ Pivot To Lowerst Center
	+ Pivot to Local Face
	
Materials & UV
	+ View Material ID
	+ Select Invalid Material ID
	+ Remove Dead UV's
	+ Transform UV's
	+ Get/Set Ratio
	+ Scale UV by Percentage.
	
-------------------------------------
Author : Kailash-D
email : kailash.d@dhruva.com
-------------------------------------
*/
DHR_toolVersion = undefined
DHR_toolServer = undefined
if doesFileExist (PathConfig.AppendPath (getFileNamePath (getThisScriptFileName())) "version.ini") then
(
	DHR_toolVersion = (GetIniSetting (PathConfig.AppendPath (getFileNamePath (getThisScriptFileName())) "version.ini") "Info" "Version") as float
	DHR_toolServer = (GetIniSetting (PathConfig.AppendPath (getFileNamePath (getThisScriptFileName())) "version.ini") "Info" "Server")
)
else
(
	DHR_toolVersion = 0.0
)
DHR_maxVersion = maxVersion()
DHR_tetraToolBoxMaxWindowSize = [174,1100]
fn LoadScripts =
(
	Directory = dotNetClass "System.IO.Directory"
	local rootDir = getFileNamePath (getThisScriptFileName())
	local scriptDir = PathConfig.appendPath rootDir @"max\scripts"
	local scriptFiles = Directory.GetFiles scriptDir "*" 
	for file in scriptFiles do
	(
		filein file
	)
)
LoadScripts()
try(destroyDialog DHR_TetraToolBox)catch()
rollout DHR_TetraToolBox ("TeTRA Toolbox v"+DHR_toolVersion as string) width:162 height:936
(
	subRollout 'DHR_TetraToolBox_SubRollout' "" pos:[-1,-1] width:DHR_tetraToolBoxMaxWindowSize.x height:DHR_tetraToolBoxMaxWindowSize.y align:#left
	fn DotnetButtonLayout ctrl alignment:unsupplied =
	(
		try
		(
			c_Backcolor = (dotnetClass "System.Drawing.Color").FromArgb 50 50 50 
			c_Forecolor = (dotnetClass "System.Drawing.Color").FromArgb 180 180 180
			ctrl.ForeColor = c_Forecolor
			ctrl.BackColor = c_Backcolor	
			ctrl.FlatStyle = ctrl.FlatStyle.Flat
			ctrl.FlatAppearance.BorderSize = 0
		)catch()
		if alignment == unsupplied do
		(
			ctrl.TextAlign = ctrl.TextAlign.MiddleLeft
		)
		if alignment == "Center" do
		(			
			ctrl.TextAlign = ctrl.TextAlign.MiddleCenter
		)
	)
	rollout DHR_TetraToolBox_Mesh "Mesh" rolledup:false
	(
		dotNetControl 'btnSetBackFaceCullOnOn' "Button" pos:[4,4] width:152 height:26 align:#left
		dotNetControl 'btnResetXForm' "Button" pos:[4,33] width:152 height:26 align:#left
		dotNetControl 'btnResetXFormMirrored' "Button" pos:[4,62] width:152 height:26 align:#left
		dotNetControl 'btnRemoveDeadIsoVerts' "Button" pos:[4,91] width:152 height:26 align:#left
		dotNetControl 'btnCheckNGon' "Button" pos:[4,119] width:152 height:26 align:#left
		dotNetControl 'btnSelectNonSmoothing' "Button" pos:[4,147] width:152 height:26 align:#left
		dotNetControl 'btnSelectMultipleSmoothing' "Button" pos:[4,175] width:152 height:26 align:#left
		dotNetControl 'btnRemoveZeroFaceObjects' "Button" pos:[4,203] width:152 height:26 align:#left
		dotNetControl 'btnApplyRandomWirecolor' "Button" pos:[4,231] width:152 height:26 align:#left	
		dotNetControl 'btnRemoveCollisionMaterials' "Button" pos:[4,259] width:152 height:26 align:#left	
		
		--events
		on DHR_TetraToolBox_Mesh open do
		(
			--Dotnet Control 
			btnSetBackFaceCullOnOn.Text = "Backface Cull On"   		 
			btnResetXForm.Text = "Reset XForm"
			btnResetXFormMirrored.Text = "Reset XForm Mirrored"
			btnRemoveDeadIsoVerts.Text = "Remove Dead/Iso Vertices"
			btnSelectNonSmoothing.Text = "Select Non Smoothing"
			btnSelectMultipleSmoothing.Text = "Select Multiple Smoothing"
			btnCheckNGon.Text = "Check NGon"
			btnRemoveZeroFaceObjects.Text = "List Objects with Null Faces"
			btnApplyRandomWirecolor.Text = "Apply Wirecolor"
			btnRemoveCollisionMaterials.Text = "Remove Collision Materials"
			
			DotnetButtonLayout btnSetBackFaceCullOnOn
			DotnetButtonLayout btnResetXForm
			DotnetButtonLayout btnResetXFormMirrored
			DotnetButtonLayout btnRemoveDeadIsoVerts
			DotnetButtonLayout btnSelectMultipleSmoothing
			DotnetButtonLayout btnSelectNonSmoothing
			DotnetButtonLayout btnCheckNGon
			DotnetButtonLayout btnRemoveZeroFaceObjects
			DotnetButtonLayout btnApplyRandomWirecolor
			DotnetButtonLayout btnRemoveCollisionMaterials
		)
		on DHR_TetraToolBox_Mesh rolledUp bState do
		(
			if (bState == true) then
			(
				DHR_TetraToolBox.height += DHR_TetraToolBox_Mesh.height
				print DHR_TetraToolBox.height
			)
			else
			(
				DHR_TetraToolBox.height -= DHR_TetraToolBox_Mesh.height
			)
		)
		on btnSetBackFaceCullOnOn click e do
		(
			with undo on
			(
				SetBackFaceCullOn()
			)
		)
		on btnResetXForm click e do
		(
			with undo on 
			(
				ResetXForms false
			)
		)
		on btnResetXFormMirrored click e do
		(
			with undo on
			(
				ResetXForms true
			)
		)
		on btnCheckNGon click e do
		(
			GetNonPolyFaces()
		)
		on btnSelectMultipleSmoothing click e do
		(
			if selection.count > 0 do
			(
				for obj in selection do GetMultipleSmoothing obj
			)
		)
		on btnSelectNonSmoothing click e do
		(
			if selection.count > 0 do
			(
				for obj in selection do SelectNonSmoothingFaces obj
			)
		)
		on btnRemoveDeadIsoVerts click e do
		(
			if selection.count > 0 then
			(
				RemoveDeadIsoVertices()
			)
			else
			(
				MessageBox "Select atleast one Object"
			)
		)
		on btnRemoveZeroFaceObjects click e do
		(			
			actionMan.executeAction 0 "40472"
			ClearListener()
			zeroFaceObjects = ListObjectWithZeroFaces()
			format "Objects with Zero Faces\n"
			format "----------------------------------\n"
			for obj in zeroFaceObjects do
			(
				format "%\n" obj
			)
		)
		on btnApplyRandomWirecolor Click e do
		(
			SetWireColor()
		)
		on btnRemoveCollisionMaterials Click e do
		(
			RemoveCollisionMaterials()
		)
	)
	rollout DHR_TetraToolBox_Pivot "Pivot" rolledup:true
	(	
		dotNetControl 'btnPivotToWorld' "Button" pos:[4,4] width:152 height:26 align:#left
		dotNetControl 'btnPivotToCenter' "Button" pos:[4,33] width:152 height:26 align:#left
		dotNetControl 'btnPivotToLowestCenter' "Button" pos:[4,62] width:152 height:26 align:#left
		dotNetControl 'btnPivotToLocalFace' "Button" pos:[4,91] width:152 height:26 align:#left
		
		on DHR_TetraToolBox_Pivot open do
		(
			btnPivotToWorld.Text = "Pivot to World"
			btnPivotToCenter.Text = "Pivot to Center"
			btnPivotToLowestCenter.Text = "Pivot to Lowest Center"
			btnPivotToLocalFace.Text = "Pivot to Local Face"
			
			DotnetButtonLayout btnPivotToWorld
			DotnetButtonLayout btnPivotToCenter
			DotnetButtonLayout btnPivotToLowestCenter
			DotnetButtonLayout btnPivotToLocalFace
		)		
		on btnPivotToWorld Click e do 
		(
			with undo on
			(
				SetPivot "World"
			)
		)
		on btnPivotToCenter Click e do 
		(
			with undo on
			(
				SetPivot "Center"
			)
		)
		on btnPivotToLowestCenter Click e do
		(
			with undo on
			(
				SetPivot "Lowest"
			)
		)
		on btnPivotToLocalFace Click e do 
		(
			with undo on
			(
				SetPivot "Local"
			)
		)
		on DHR_TetraToolBox_Pivot rolledUp bState do
		(
			if (bState == true) then
			(
				DHR_TetraToolBox.height += DHR_TetraToolBox_Pivot.height
				print DHR_TetraToolBox.height
			)
			else
			(
				DHR_TetraToolBox.height -= DHR_TetraToolBox_Pivot.height
			)
		)
	)
	rollout DHR_TetraToolBox_MaterialUV "Materials  & UV" rolledup:true
	(
		dotNetControl 'btnSelectInvalidMaterialID' "button" pos:[8,8] width:144 height:24 align:#left
		GroupBox 'grpUV' "UV" pos:[8,40] width:144 height:216 align:#left
		dotNetControl 'btnClearDeadChannels' "button" pos:[16,80] width:128 height:24 align:#left
		label 'lbl2' "Remove After" pos:[16,56] width:72 height:16 align:#left
		spinner 'deadUVVal' "" pos:[96,56] width:48 height:16 range:[1,1000,2] type:#integer align:#left
		dotNetControl 'btnTransformLeft' "button" pos:[16,136] width:62 height:24 align:#left
		dotNetControl 'btnTransformRight' "button" pos:[80,136] width:62 height:24 align:#left
		dotNetControl 'btnTransformDown' "button" pos:[16,162] width:62 height:24 align:#left
		dotNetControl 'btnTransformUp' "button" pos:[80,162] width:62 height:24 align:#left
		label 'lbl3' "Transform" pos:[16,112] width:56 height:16 align:#left
		spinner 'transformVal' "" pos:[88,112] width:56 height:16 range:[1,100,0] align:#left
		label 'lbl10' "Scale" pos:[16,200] width:56 height:16 align:#left
		spinner 'scaleUVVal' "" pos:[72,200] width:56 height:16 range:[1,65536,10] type:#float align:#left
		label 'lbl11' "%" pos:[128,200] width:16 height:16 align:#left
		dotNetControl 'btnScaleUVByPercentage' "button" pos:[16,224] width:128 height:24 align:#left
		
		local texelRatio = 0	
		
		on DHR_TetraToolBox_MaterialUV open do
		(
			transformVal.value = 1.0			
			btnSelectInvalidMaterialID.Text = "List Invalid Mat ID"
			btnClearDeadChannels.Text = "Clear Dead UV Channels"
			btnTransformRight.Text = "Right"
			btnTransformLeft.Text = "Left"
			btnTransformUp.Text = "Up"
			btnTransformDown.Text = "Down"			
			btnScaleUVByPercentage.Text = "Scale By Percentage"
			
			DotnetButtonLayout btnSelectInvalidMaterialID alignment:"Center"
			DotnetButtonLayout btnClearDeadChannels
			DotnetButtonLayout btnTransformUp alignment:"Center"
			DotnetButtonLayout btnTransformDown alignment:"Center"
			DotnetButtonLayout btnTransformLeft alignment:"Center"
			DotnetButtonLayout btnTransformRight alignment:"Center"
			DotnetButtonLayout btnScaleUVByPercentage
		)
		on DHR_TetraToolBox_MaterialUV rolledUp bState do
		(
			if (bState == true) then
			(
				DHR_TetraToolBox.height += DHR_TetraToolBox_MaterialUV.height
				print DHR_TetraToolBox.height
			)
			else
			(
				DHR_TetraToolBox.height -= DHR_TetraToolBox_MaterialUV.height
			)
		)
		on btnSelectInvalidMaterialID click e do
		(
			if selection.count > 0 do
			(
				MessageBox(ListViewMaterialID (CheckMaterialID())) beep:false title:"Check Material ID"
				ClearListener()
				format "%" (ListViewMaterialID (CheckMaterialID()))
			)
		)
		on btnClearDeadChannels click e do
		(
			if selection.count > 0 then
			(
				for each in selection do
				(
					ClearUnusedChannels each (deadUVVal.value)
				)
			)
			else
			(
				MessageBox "Select atleast one object" title:"TETRA_QATOOL"
			)
		)
		on btnTransformLeft click e do
		(
			TransformUV "LEFT" transformVal.value
		)
		on btnTransformRight click e do
		(
			TransformUV "RIGHT" transformVal.value
		)
		on btnTransformDown click e do
		(
			TransformUV "DOWN" transformVal.value
		)
		on btnTransformUp click e do
		(
			TransformUV "UP" transformVal.value
		)
		on btnScaleUVByPercentage click e do
		(
			if scaleUVVal.value > 0.0 and scaleUVVal.value < 100.0 then
			(
				scaleValue = (scaleUVVal.value/100.0)
				scaleValue += 1
			)
			else
			(
				scaleValue = (scaleUVVal.value/50.0)
			)
			ScaleUVByPercentage scaleValue			
		)
	)	
	rollout DHR_TetraToolBox_Update "About" rolledup:true
	(		
		dotNetControl 'btnUpdateToolBox' "Button" pos:[8,28] width:144 height:26 align:#left
		label 'lblAbout' "" pos:[8,6] width:144 height:16 align:#left		
		on DHR_TetraToolBox_Update open do
		(
			lblAbout.caption = "Toolbox v" + DHR_toolVersion as string
			btnUpdateToolBox.Text = "Update Toolbox"
			DotnetButtonLayout lblAbout alignment:"center"
			DotnetButtonLayout btnUpdateToolBox alignment:"center"
		)
		on btnUpdateToolBox Click e do
		(
			if DHR_toolServer == "Local" do
			(
				serverVersionFile = @"E:\Max\tetraToolbox\files\version.ini"
			)
			if DHR_toolServer == "Remote" do
			(
				serverVersionFile = @"\\dhr-trsfr-agt02\Tetra\Public\Tools\tetraToolbox\files\version.ini"
			)
			if doesFileExist serverVersionFile do
			(
				serverVersion = GetINISetting serverVersionFile "Info" "Version" as float
			)
			if DHR_toolVersion != serverVersion then
			(
				MessageBox ("New Version Available\nVersion : " + serverVersion as string) title:"TETRA TOOLBOX UPDATE"
				if DHR_toolServer == "Local" do
				(
					filein @"E:\Max\tetraToolbox\ToolboxInstaller.ms"
				)
				if DHR_toolServer == "Remote" do
				(
					filein @"\\dhr-trsfr-agt02\Tetra\Public\Tools\tetraToolbox\ToolboxInstaller.ms"
				)				
				destroyDialog DHR_TetraToolBox
			)
			else
			(
				MessageBox "Toolbox is up-to-date" title:"TETRA TOOLBOX UPDATE"
			)			
		)
		on DHR_TetraToolBox_Update rolledUp bState do
		(
			if (bState == true) then
			(
				DHR_TetraToolBox.height += DHR_TetraToolBox_Update.height
				print DHR_TetraToolBox.height
			)
			else
			(
				DHR_TetraToolBox.height -= DHR_TetraToolBox_Update.height
			)
		)
	)
	on DHR_TetraToolBox open do
	(
		addSubRollout DHR_TetraToolBox_SubRollout DHR_TetraToolBox_Mesh
		addSubRollout DHR_TetraToolBox_SubRollout DHR_TetraToolBox_Pivot
		addSubRollout DHR_TetraToolBox_SubRollout DHR_TetraToolBox_MaterialUV
		addSubRollout DHR_TetraToolBox_SubRollout DHR_TetraToolBox_Update
	)
)
if DHR_maxVersion[1] > 18000 then
(
	createDialog DHR_TetraToolBox width:DHR_tetraToolBoxMaxWindowSize.x height:752
)
else
(
	createDialog DHR_TetraToolBox width:DHR_tetraToolBoxMaxWindowSize.x height:402
)
