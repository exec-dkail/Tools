MacroScript MayaImporter
category:"Importer" 
tooltip:"Import Objects from Maya"
ButtonText: "Import" 
(
	local xmlDoc = dotNetObject "System.Xml.XmlDocument"
	local importFileName = undefined
	
	function ImportMayaObject =
	(
		importFileName = getOpenFileName caption:"Import Files" types:"gw::OBJ-Importer (*.OBJ)|*.obj|Autodesk (*.FBX)|*.fbx"
		if importFileName != undefined do ImportFile importFileName #noPrompt		
	)	
	function GetXMLFile file = 
	(
		xmlFile = undefined
		if file != undefined do
		(
			xmlFolder = getFileNamePath file
			xmlFile = PathConfig.AppendPath xmlFolder ((getFileNameFile file)+".xml")
		)
		return xmlFile
	)	
	function GetMeshData xFile =
	(	
		xmlDoc = dotNetObject "System.Xml.XmlDocument"
		xmlDoc.Load xFile
		xmlQuery = xmlDoc.SelectNodes "MeshData"
		cNodesArray = for i = 0 to xmlQuery.Count-1 collect xmlQuery.ItemOf[i].ChildNodes
		return cNodesArray
	)		
	function ExtractMeshData xFile =
	(
		mData = #()
		cNodes = GetMeshData xFile
		for cn in cNodes do
		(
			local objName = undefined
			local objFaceList = undefined			
			for i = 0 to cn.Count-1 do
			(
				objName = cn.ItemOf[i].GetAttribute "Name"
				objFaceList = (cn.ItemOf[i].ChildNodes).ItemOf[0].InnerXml
				Append mData #(objName, (execute objFaceList))				
			)			
		)
		return mData
	)	
	function ConvertArrToBitArr arr =
	(
		bArr = #()
		for item in arr do Append bArr (item as BitArray)
		return bArr
	)	
	function ResetObject obj =
	(
		vertexWeldMod = vertex_Weld()
		normalMod = Edit_Normals()
		
		addModifier obj vertexWeldMod
		vertexWeldMod.threshold = 0
		
		addModifier obj normalMod		
		normalMod.Reset()
		
		CollapseStack obj
	)	
	function ApplySmoothingGroups obj data = 
	(
		if obj != undefined do
		(
			ConvertTo obj Editable_Poly			
			ResetObject obj
			
			-- Clear All Smoothing Group
			polyop.setFaceSelection obj #all
			polyop.setFaceSmoothGroup obj (polyop.getFaceSelection obj) 0
			
			-- Apply New Smoothing Group
			for indx = 1 to data.count do
			(
				smoothGrp = (2 ^ indx)	
				if data[indx].numberSet > 0 do
				(
					polyop.setFaceSmoothGroup obj data[indx] smoothGrp add:true
				)		
			)
		)
	)	
	function ProcessImportedObjects xFile = 
	(
		meshData = ExtractMeshData xFile
		obj = undefined
		objSGData = undefined 
		for data in meshData do
		(
			obj = GetNodeByName data[1]
			objSGData = ConvertArrToBitArr data[2]	
			ApplySmoothingGroups obj objSGData
		)
	)	
	
	ImportMayaObject()
	meshDataFile = GetXMLFile importFileName
	if meshDataFile != undefined and importFileName != undefined do
	(
		if doesFileExist meshDataFile then
		(
			ProcessImportedObjects meshDataFile
		)
		else
		(
			MessageBox ("No MeshData.xml found in : " + (getFileNamePath importFileName)) title:"MayaImporter" 
		)
	)		
	gc light:true
)
