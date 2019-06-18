import maya.api.OpenMaya as om
import pymel.core as pm
import maya.cmds as cmds
import math as math
import xml.etree.ElementTree as et
import os

def FormattedXml(elem, level=0):
	i = "\n" + level*"  "
	if len(elem):
		if not elem.text or not elem.text.strip():
			elem.text = i + "  "
		if not elem.tail or not elem.tail.strip():
			elem.tail = i
			for elem in elem:
				FormattedXml(elem, level+1)
		if not elem.tail or not elem.tail.strip():
			elem.tail = i
	else:
		if level and (not elem.tail or not elem.tail.strip()):
			elem.tail = i


def CreateXml(xroot,objectname,facelist):
	objdata = et.SubElement(xroot,'Object')
	objdata.set('Name',objectname)
	data = et.SubElement(objdata,'Data')
	data.text = facelist

def getEdgeHardness(edge):
	pm.polySelectConstraint(dis=True)
	pm.select(edge)
	pm.polySelectConstraint(m=2, t=0x8000, sm=1)
	selList = pm.ls(sl=True)
	if len(selList)>0:
		pm.polySelectConstraint(dis=True)
		pm.select(clear=True)
		return True
	else:
		pm.polySelectConstraint(dis=True)
		pm.select(clear=True)
		return False

def getCommonEdge(faceItr,face1,face2):
	faceItr.setIndex(face1)
	edgeSet1 = set(faceItr.getEdges())
	faceItr.setIndex(face2)
	edgeSet2 = set(faceItr.getEdges())
	s = edgeSet1.intersection(edgeSet2)
	if len(s)==0:
		return None
	else: return s.pop()

def getFirstHardEdge(tempEdgeItr,circleEdgeList):
	for index in range(0,len(circleEdgeList)):
		tempEdgeItr.setIndex(circleEdgeList[index])
		if not tempEdgeItr.isSmooth:
			return index,circleEdgeList[index]

def createEdgePartitions(tempEdgeItr,circleEdgeList):
	firstHardEdge = getFirstHardEdge(tempEdgeItr,circleEdgeList)
	if firstHardEdge is None:
		returnValue = []
		for i in range(0,len(circleEdgeList)):
			returnValue.append(circleEdgeList[i])
		returnValue.append(circleEdgeList[0])
		return [returnValue]
	partitions = []
	hardEdge = firstHardEdge[1]
	tempPartition = []
	i=firstHardEdge[0]
	innerTrigger = True
	whileFirst = True
	while(True):
		tempPartition.append(circleEdgeList[i])
		if innerTrigger:
			if i==firstHardEdge[0] and not whileFirst: break
			innerTrigger = False
			whileFirst = False
			i=i+1
			if i==len(circleEdgeList):i=0
			continue
		else:
			tempEdgeItr.setIndex(circleEdgeList[i])
			if not tempEdgeItr.isSmooth:
				partitions.append(list(tempPartition))
				del tempPartition[:]
				i=i-1
				innerTrigger=True
			i=i+1
			if i==len(circleEdgeList):i=0
	return partitions

def getLinkedFaces(tempEdgeItr,partitions):
	facePartitions=[]
	tempFacePartitions=[]
	for eachList in partitions:
		i=0
		while(True):
			if i==len(eachList)-1:
				facePartitions.append(list(tempFacePartitions))
				del tempFacePartitions[:]
				break
			tempEdgeItr.setIndex(eachList[i])
			faceList1 = set(tempEdgeItr.getConnectedFaces())
			tempEdgeItr.setIndex(eachList[i+1])
			faceList2 = set(tempEdgeItr.getConnectedFaces())
			s=faceList1.intersection(faceList2)
			if not len(s)==0:
				tempFacePartitions.append(faceList1.intersection(faceList2).pop())
			i=i+1
	return facePartitions

def getForbiddenFaceList(linkedFacesList,edgePartitionsList,vertIndex,faceIndex):
	linkedFaces = linkedFacesList[vertIndex]
	edgePartitions = edgePartitionsList[vertIndex]
	forbiddenList=[]
	for index,partition in enumerate(linkedFaces):
		if faceIndex in partition:
			forbiddenList = forbiddenList + [item for i,item in enumerate(linkedFaces) if i != index]
	return [item for sublist in forbiddenList for item in sublist]

def getSmoothGrps(object):
	edgeItr = om.MItMeshEdge(object)
	tempEdgeItr = om.MItMeshEdge(object)
	faceItr = om.MItMeshPolygon(object)
	tempFaceItr = om.MItMeshPolygon(object)
	vertItr = om.MItMeshVertex(object)
	tempVertItr = om.MItMeshVertex(object)
	softList = []
	faceGrp = []
	for i in range(0,edgeItr.count()):
		softList.append(edgeItr.isSmooth)
		edgeItr.next()
	for i in range(0,faceItr.count()):
		faceGrp.append(1)
		faceItr.next(0)
	faceItr.reset()
	# face hardening
	for i in range(0,faceItr.count()):
		connectedEdges = faceItr.getEdges()
		forbiddenNums = []
		currIndex = faceItr.index()
		for j in range(0,len(connectedEdges)):
			tempEdgeItr.setIndex(connectedEdges[j])
			if tempEdgeItr.onBoundary():
				continue
			vertex1 = tempEdgeItr.vertexId(0)
			vertex2 = tempEdgeItr.vertexId(1)
			tempVertItr.setIndex(vertex1)
			faceSet1 = set(tempVertItr.getConnectedFaces())
			tempVertItr.setIndex(vertex2)
			faceSet2 = set(tempVertItr.getConnectedFaces())
			faceSet = faceSet1.union(faceSet2)
			faceSet.remove(currIndex)
			for faceIndex in faceSet:
				forbiddenNums.append(faceGrp[faceIndex])
		ourNum = 1
		while(True):
			if ourNum not in forbiddenNums:
				faceGrp[currIndex] = ourNum
				break;
			else:
				ourNum = ourNum * 2
		faceItr.next(0)
	faceGrptemp = faceGrp[:]
	edgeItr.reset()
	edgePartitionsList=[]
	linkedFacesList=[]
	for z in range(0,vertItr.count()):
		circleEdgeList = vertItr.getConnectedEdges()
		edgePartitions = createEdgePartitions(tempEdgeItr,circleEdgeList)
		linkedFaces = getLinkedFaces(tempEdgeItr,edgePartitions)
		edgePartitionsList.append(edgePartitions)
		linkedFacesList.append(linkedFaces)
		vertItr.next()
	vertItr.reset()
	for z in range(0,vertItr.count()):
		linkedFaces = linkedFacesList[z]
		for i in range(0,len(linkedFaces)):
			ourlist = [item for a,item in enumerate(linkedFaces) if a!=i]
			ourlist = [item for sublist in ourlist for item in sublist]
			tempForbiddenList = ourlist
			for face in linkedFaces[i]:
				tempFaceItr.setIndex(face)
				thisFaceVerts=set(tempFaceItr.getVertices())
				thisFaceVerts.remove(int(vertItr.index()))
				for vertex in thisFaceVerts:
					tempForbiddenList = tempForbiddenList + getForbiddenFaceList(linkedFacesList,edgePartitionsList,vertex,face)
			tempForbiddenFaces= tempForbiddenList[:]
			tempForbiddenList = [faceGrp[item] for item in tempForbiddenList]
			if len(tempForbiddenList) == 0:tempForbiddenList.append(0)
			for index in range(0, len(tempForbiddenList) - 1):
				tempForbiddenList[0] = tempForbiddenList[0] | tempForbiddenList[index + 1]
			bitter = 1
			while(True):
				if bitter & tempForbiddenList[0] == 0:
					break
				else:
					bitter = bitter*2
			for j in linkedFaces[i]:
				faceGrp[j] = faceGrp[j] | bitter
		vertItr.next()
	smoothingGroups = []
	for group in range(0,32):
		tempList=[]
		for faceIndex,face in enumerate(faceGrp):
			if int(math.pow(2,group)) & face == int(math.pow(2,group)):
				tempList.append(faceIndex+1)
		smoothingGroups.append(tempList)
	return faceGrp,smoothingGroups


def main():
	actSelList = om.MGlobal.getActiveSelectionList()
	filePath = pm.fileDialog2(fileFilter='gw::OBJExport (.obj);;Autodesk FBX (.fbx)',cap="Export as")
	fileFolderPath = os.path.dirname(filePath[0])
	fileName,fileType = filePath[0].split('/')[-1].split('.')
	if fileType == 'fbx':
		cmds.file(filePath[0], force=True, options="v=0", typ="FBX export", pr=True, es=True)
	elif fileType == 'obj':
		cmds.file(filePath[0], force=True, options="groups=1;ptgroups=1;materials=1;smoothing=1;normals=1", typ="OBJexport", pr=True, es=True)

	root = et.Element('MeshData')
	for object in range(0,actSelList.length()):
		faceGrp, smoothingGroups = getSmoothGrps(actSelList.getDagPath(object))
		CreateXml(root,actSelList.getDagPath(object).fullPathName().split('|')[-1],unicode(smoothingGroups).replace('[','#(').replace(']',')'))
	FormattedXml(root)
	tree = et.ElementTree(root)
	tree.write(fileFolderPath+'/'+fileName+'.xml')


if __name__=='__main__':
	main()


