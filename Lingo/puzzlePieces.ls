-- PUZZLE PIECES (parent script --
--
-- © March 2000, James Newton <newton@planetb.fr>
--
-- This parent script responds to one public method:
--
-- (scriptObject).createPuzzleData(bitmapMember, sideCount, showImage)
--
-- This creates a set of puzzle-shaped bitmap members which assemble
-- to give the image defined by bitmapMember.



-- PROPERTY DECLARATIONS --

property pEdgeList
property pVectorMember
property pSourceImage
property pSourceWidth
property pSourceHeight
property pHCount
property pVCount
property pPieceSize
property pBorders
property p3D



--PUBLIC METHOD --

on createPuzzleData(me, bitmapMember, sideCount, showImage, no3D) ----
  -- PARAMETERS:
  -- <bitmapMember>: reference to a bitmap member used for the image
  -- <sideCount>:    integer number of pieces along the shortest side
  -- <showImage>:    integer between 1 and 255 used to determine the 
  --                 blendLevel of the background image
  -- <no3D>:         pieces have not hilite or shadow if no3D = TRUE
  --
  -- ACTION: creates a series of puzzle shaped bitmap members based on
  -- the original image.  The corners of the each piece will form
  -- a square (the interlocking areas will extend beyond the square).
  -- If the original image cannot be tiled with an integer number of
  -- squares a border will be clipped around the edges.
  --
  -- RETURNS: a property list with the format
  -- [#pieces: [<list of piece members>], \ 
  --  #edge:  <integer number of pixels between corners>, 
  --  #image: <bitmap member showing the borders + background image>,
  --  #border:<point(leftBorder, topBorder)>,
  --  #hCount:<number of columns of pieces>,
  --  #vCount:<number of rows of pieces)>]
  --------------------------------------------------------------------
  
  puzzleDataList = [:]
  
  -- Create a copy of the bitmap member's image so we can alter it
  borderImage   = bitmapMember.image.duplicate()
  pSourceHeight = borderImage.height
  pSourceWidth  = borderImage.width
  
  -- Determine number of pieces horizontally (pHCount) and vertically
  -- (pVCount) and the dimensions of each piece (pPieceCount)
  dimensions = me.getDimensions(sideCount)
  pPieceSize = dimensions.pieceSize
  pHCount    = dimensions.hCount
  pVCount    = dimensions.vCount
  
  puzzleDataList[#edge]   = pPieceSize
  puzzleDataList[#hCount] = pHCount
  puzzleDataList[#vCount] = pVCount
  
  -- Determine which part of the image will be used for the puzzle and
  -- what borders areas are left over for the background image
  puzzleWidth  = pHCount * pPieceSize
  puzzleHeight = pVCount * pPieceSize
  leftBorder   = (pSourceWidth  - puzzleWidth) / 2
  topBorder    = (pSourceHeight - puzzleHeight) / 2
  pBorders      = [leftBorder, topBorder, leftBorder, topBorder]
  
  -- Decide whether to create pieces with hilite and shadow
  p3D = (no3D <> TRUE)
  
  imageRect    = rect(0, 0, puzzleWidth, puzzleHeight) + pBorders
  pSourceImage  = borderImage.crop(imageRect)
  
  if showImage then
    -- Create a bitmap member for the background / borders if required
    borderImage.fill(imageRect, rgb(255, 255, 255))
    borderImage.copyPixels( \
pSourceImage, \
imageRect, \
pSourceImage.rect, \
[#blendLevel: showImage] \
)
    
    borderMember            = new(#bitmap)
    borderMember.image      = borderImage
    puzzleDataList[#image]  = borderMember
    puzzleDataList[#border] = point(leftBorder, topBorder)
  end if
  
  -- Now we have the dimensions we can create the puzzle pieces
  puzzleDataList[#pieces] = me.createPuzzlePieces()  
  
  return puzzleDataList
end createPuzzleData



-- PRIVATE METHODS --

on createPuzzlePieces(me) --------------------------------------------
  -- Called by createPuzzleData()
  --
  -- RETURNS:
  -- a linear list of the bitmap members created for the puzzle
  --
  -- The shape of each interlocking edge of each piece is unique.
  -- The shape of the piece is first created by manipulating the
  -- vertexList of a temporary Vector Shape member (no stroke, black
  -- fill).
  --
  -- The first vertex point is placed at the top left corner.  Three
  -- more vertex points are added for each side: one either side of
  -- the "neck" of the interlocking area, and one at the top of the
  -- "head".  By altering the position of the head and the angles of
  -- the handles of these three vertex points, a unique shape is
  -- created for each side.
  --
  -- Pieces on the edges and at the corners of the puzzle have to be
  -- treated separately to give them straight sides.
  --
  -- NOTE: this handler is fairly long as the same instructions need
  -- to be repeated with slight variations for each of the four edges.
  --------------------------------------------------------------------
  
  piecesList = []
  
  -- Create a temporary Vector Shape member and use it as a cookie-
  -- cutter mask for the puzzle pieces
  pVectorMember = me.createVectorShapeMember()
  
  pEdgeList = [] -- Ensures that all interlocking edges are unique
  topsList  = [] -- Ensures that pieces interlock with the row above
  edge      = [] -- Declared here so that the script will compile 
  
  repeat with v = 1 to pVCount   -- For each row of the puzzle...
    repeat with h = 1 to pHCount -- ... create the pieces
      bezierList = [[vertex: point(-50, -50)]]
      
      -- Prepare to create the top of the piece (this is done last)
      if v = 1 then
        -- This is the top row: pieces will have flat tops
        topEdge = #flat -- arbitrary non-list value
      else 
        -- Use the same top edge as the piece above
        topEdge = topsList[h]
      end if
      
      if h = 1 then
        -- The left edge is flat
      else
        -- Use the <edge> created for the previous piece's right edge
        cheek  = [:]
        cheek[#vertex] = point(-50, -8)
        handle = point(edge[#curve], edge[#angle])
        cheek[#handle1] =  handle / 5.0
        cheek[#handle2] = -handle
        bezierList.append(cheek)
        -- Midpoint
        vertex = [:]
        vertex[#vertex] = point(-25, edge[#tilt])
        handle = point(edge[#slant], -25)
        vertex[#handle1] = -handle
        vertex[#handle2] = handle
        bezierList.append(vertex)
        -- Second cheek
        cheek = [:]
        cheek[#vertex] = point(-50, 8)
        handle = point(edge[#curve], edge[#angle])
        cheek[#handle1] = -handle
        cheek[#handle2] = handle / 5.0
        bezierList.append(cheek)
      end if
      bezierList.append([#vertex: point(-50, 50)]) 
      
      if v = pVCount then
        -- This is the bottom row: pieces will have flat bottoms
      else
        -- Create a unique curve for the lower edge and save it
        edge = randomEdge(topsList, h)
        -- Calculate the vertexList for the lower edge: first cheek
        cheek  = [:]
        cheek[#vertex] = point(-8, 50)
        handle = point(edge[#angle], edge[#curve])
        cheek[#handle1] = -handle / 5.0
        cheek[#handle2] = handle
        bezierList.append(cheek)
        -- Midpoint
        vertex = [:]
        vertex[#vertex] = point(edge[#tilt], 25)
        handle = point(25, edge[#slant])
        vertex[#handle1] = handle
        vertex[#handle2] = -handle
        bezierList.append(vertex)
        -- Second cheek
        cheek = [:]
        cheek[#vertex] = point(8, 50)
        handle = point(edge[#angle], edge[#curve])
        cheek[#handle1] = handle
        cheek[#handle2] = -handle / 5.0
        bezierList.append(cheek)
      end if
      bezierList.append([#vertex: point(50, 50)])
      
      if h = pHCount then
        -- Right edge is flat
      else
        -- Create a unique curve for the right edge and remember it
        edge = randomEdge()
        -- Calculate the vertexList for the lower edge: first cheek
        cheek  = [:]
        cheek[#vertex] = point(50, 8)
        handle = point(edge[#curve], edge[#angle])
        cheek[#handle1] = handle / 5.0
        cheek[#handle2] = -handle
        bezierList.append(cheek)
        -- Midpoint
        vertex = [:]
        vertex[#vertex] = point(75, edge[#tilt])
        handle = point(edge[#slant], -25)
        vertex[#handle1] = handle
        vertex[#handle2] = -handle
        bezierList.append(vertex)
        -- Second cheek
        cheek = [:]
        cheek[#vertex] = point(50, -8)
        handle = point(edge[#curve], edge[#angle])
        cheek[#handle1] = -handle
        cheek[#handle2] = handle / 5.0
        bezierList.append(cheek)
      end if      
      bezierList.append([#vertex: point(50, -50)])
      
      if listP(topEdge) then
        -- Calculate the vertexList for the top edge: first cheek
        cheek  = [:]
        cheek[#vertex] = point(8, -50)
        handle = point(topEdge[#angle], topEdge[#curve])
        cheek[#handle1] = -handle / 5.0
        cheek[#handle2] = handle
        bezierList.append(cheek)
        -- Midpoint
        vertex = [:]
        vertex[#vertex] = point(topEdge[#tilt], -75)
        handle = point(-25, -topEdge[#slant])
        vertex[#handle1] = handle
        vertex[#handle2] = -handle
        bezierList.append(vertex)
        -- Second cheek
        cheek = [:]
        cheek[#vertex] = point(-8, -50)
        handle = point(topEdge[#angle], topEdge[#curve])
        cheek[#handle1] = handle
        cheek[#handle2] = -handle / 5.0
        bezierList.append(cheek)
      end if 
      bezierList.append([vertex: point(-50, -50)])
      
      -- Create the bitmap for the current piece and add it to list
      pieceMember = me.createPuzzleBitmap(bezierList, h, v)
      piecesList.append(pieceMember)
    end repeat
  end repeat
  
  -- pVectorMember is no longer required
  pVectorMember.erase()
  
  return piecesList
end createPuzzlePieces



on createVectorShapeMember(me) ----------------------------------------
  -- Called by createPuzzlePieces()
  --
  -- RETURNS: a temporary Vector Shape member that will be used by the
  -- createPuzzleBitmap() handler.  The same Vector Shape member is
  -- reused as often as necessary, and then destroyed by the same
  -- createPuzzlePieces() handler that created it.
  --
  -- The Vector Shape is given a solid  fill and no stroke, so that
  -- its alpha channel will take the appropriate value.  The color is
  -- unimportant.
  --------------------------------------------------------------------
  
  vectorMember = new(#vectorShape)
  vectorMember.strokeWidth = 0
  vectorMember.closed      = TRUE
  vectorMember.fillMode    = #solid
  
  return vectorMember
end createVectorShapeMember



on getDimensions(me, sideCount) --------------------------------------
  -- Called by createPuzzleData()
  --
  -- RETURNS: a property list with the format
  -- [#pieceSize: <integer>, #hCount: <integer>, #vCount: <integer>]
  --
  -- This handler calculates the best fit size for the puzzle pieces,
  -- given the number of pieces that should appear along the shorter
  -- side.
  --------------------------------------------------------------------
  
  shorterSide   = min(pSourceHeight, pSourceWidth)
  pieceSize     = shorterSide / sideCount
  
  if shorterSide = pSourceHeight then --image is wider than it is high
    hCount = pSourceWidth / pieceSize
    area   = hCount * sideCount * pieceSize * pieceSize
    
    -- Check if a slightly smaller piece might fit better
    tempSize = pSourceWidth / (hCount + 1)
    if ((hCount + 1) * sideCount * tempSize * tempSize) > area then
      pieceSize = tempSize
    end if
    
    hCount = pSourceWidth / pieceSize
    vCount = sideCount
    
  else -- image is higher than it is wide
    vCount = pSourceHeight / pieceSize
    
    -- Check if a slightly smaller piece might fit better
    tempSize = pSourceHeight / (vCount + 1)
    if ((vCount + 1) * sideCount * tempSize * tempSize) > area then
      pieceSize = tempSize
    end if
    
    vCount = pSourceHeight / pieceSize
    hCount = sideCount
  end if
  
  return [#pieceSize: pieceSize, #hCount: hCount, #vCount: vCount]
end getDimensions



on createPuzzleBitmap(me, bezierList, h, v) --------------------------
  -- Called by createPuzzlePieces()
  --
  -- PARAMETERS: 
  -- <bezierList> is the list of vertex points for the shape,
  --              normalized to a 100 pixel square
  -- <h and v>    integers indicating the column and row of the piece
  --
  -- RETURNS: 
  -- A reference to a newly create bitmap member with the appropriate
  -- shape and image for this position in the puzzle.
  --
  -- Before modifying the Vector Shape member, the vertex list data
  -- must be scaled to the appropriate size.
  --
  -- The first vertex point is placed at the top left corner. The
  -- interlocking shapes extend beyond this corner, so an adjustment
  -- has to be made to ensure that the correct portion of the source
  -- image is copied.  This is done by forcing the originPoint of the
  -- Vector Shape to the top left corner of the piece's bounding
  -- rectangle.  The value of the first vertex now reflects its
  -- position within the bounding rectangle.
  --
  -- The appropriate rectangle of the source image is now copied to a
  -- new image object.  The alpha channel of the Vector Shape's image
  -- is used as copied to the new image object to give the piece its
  -- shape.
  --
  -- The alpha-channel image object is then copied to a new bitmap
  -- member, whose #useAlpha property is set to TRUE.
  --------------------------------------------------------------------
  
  -- Adjust the size and shape of the Vector Shape member
  pVectorMember.originMode = #center
  pVectorMember.vertexList = bezierList * pPieceSize / 100.0
  
  -- Determine offset of first vertex = regpoint of new bitmap
  pVectorMember.originMode = #topLeft
  adjustPoint = pVectorMember.vertexList[1][#vertex]
  adjustH     = -adjustPoint.locH
  adjustV     = -adjustPoint.locV
  
  -- Determine which part of source image appears on the piece
  rectOffset = (([h, v, h, v] - 1) * pPieceSize)
  pieceRect  = pVectorMember.rect + rectOffset
  pieceRect  = pieceRect.offset(adjustH, adjustV) -- + 0.5
  
  -- Create 32-bit image of the appropriate part of the source image
  pieceImage = image(pieceRect.width, pieceRect.height, 32)
  sourceArea = pieceImage.rect
  pieceImage.copyPixels(pSourceImage, sourceArea, pieceRect)
  
  -- Extract the alpha image and use it for the shape of the piece
  alphaImage = pVectorMember.image.extractAlpha()
  pieceImage.setAlpha(alphaImage)
  
  if p3D then
    -- Add shadow to the bottom and right edges
    shade    = me.getShading()
    option   = [#blendLevel: 128]
    pieceImage.copyPixels(shade.hilite,sourceArea-1,sourceArea,option) 
    pieceImage.copyPixels(shade.shadow,sourceArea-1,sourceArea,option)
  end if 
  
  -- Create a bitmap member to store the piece
  pieceMember = new(#bitmap)
  pieceMember.image = pieceImage
  pieceMember.useAlpha = TRUE
  pieceMember.regPoint = adjustPoint
  
  return pieceMember
end createPuzzleBitmap



on getShading(me) ----------------------------------------------------
  -- Called by createPuzzleBitmap()
  --
  -- RETURNS: a property list with the format:
  --   [#hilite: <image:1e85318>, #shadow: <image:1e84350>]
  --
  -- The hilite image contains a white line which follows the contour
  -- of the top and left edges.  The shadow image contains a black
  -- line which follows the contour of the bottom and right edges.
  --------------------------------------------------------------------
  
  shading = [:]
  
  -- Prepare temporary Vector Shape members
  hiliteMember = member(pVectorMember.duplicate())
  hiliteMember.fillMode    = #none
  hiliteMember.strokeWidth = 1
  hiliteMember.strokeColor = rgb(255, 255, 255)
  hiliteMember.closed      = FALSE
  shadowMember = member(hiliteMember.duplicate())
  
  -- Deal with the hilite to the top and left
  
  -- Move vertices from top edge to the beginning
  vertices = shadowMember.vertexList
  i = vertices.count
  vertices.deleteAt(i)
  repeat while TRUE
    vertices.addAt(1, vertices[i - 1])
    atCorner = voidP(vertices[i][#handle1])
    vertices.deleteAt(i)
    if atCorner then
      -- We've reached the top right corner
      exit repeat
    end if
  end repeat
  -- Remove right and bottom sides
  repeat while i
    i = i - 1
    if voidP(vertices[i][#handle1]) then
      if atCorner then
        -- We've reached the bottom right corner
        atCorner = FALSE
      else
        -- We've reached the bottom left corner
        exit repeat
      end if
    end if
    -- We haven't reached the bottom left corner yet
    vertices.deleteAt(i)
  end repeat
  
  hiliteMember.vertexList = vertices
  -- new(#bitmap).image = hiliteMember.image
  shading[#hilite] = hiliteMember.image.duplicate()
  hiliteMember.erase()
  
  -- Deal with the shadow to the bottom and right
  
  shadowMember.strokeColor = rgb(0, 0, 0)
  shadowMember.deleteVertex(1) -- top right
  repeat while not voidP(shadowMember.vertexList[1][#handle1])
    shadowMember.deleteVertex(1)
  end repeat
  i = shadowMember.vertexList.count
  shadowMember.deleteVertex(i) -- top left corner
  if shadowmember  = member(12) then
    nothing
  end if
  
  repeat while TRUE
    i = i - 1
    if voidP(shadowMember.vertexList[i][#handle1]) then
      -- We've reached the top right corner
      exit repeat
    else
      shadowMember.deleteVertex(i)
    end if
  end repeat
  
  -- new(#bitmap).image = shadowMember.image
  shading[#shadow] = shadowMember.image.duplicate()
  shadowMember.erase()
  
  return shading
end getLightEffect



on randomEdge(topsList, column) --------------------------------------
  -- Called by createPuzzlePieces()
  --
  -- PARAMETERS:
  -- <topsList> the list of random edges used at the bottom of the
  --            preceding row of puzzle pieces.
  -- <column>   the column in which the current piece is placed.
  --
  -- RETURNS: a property list with the format
  -- [#tilt: tilt, #slant: slant, #angle: angle, #curve: curve]
  -- #tilt  = the lateral position of the top of the head
  -- #slant = the slope of the handles at the top of the head
  -- #angle = the slope of the handles at the two neck points
  -- #curve = the bulge of the shoulders
  --
  -- Each time this function is called, a unique set of values is
  -- returned.  #angle and #curve are the same for both sides of the
  -- interlocking area.  For a greater range of puzzle pieces, a
  -- different value could be created for each side, or a greater
  -- range of values could be used for the existing variables.
  --
  -- Currently, a total of 11 * 11 * 11 * 11 = 14 641 different shapes
  -- are returned.
  --
  -- A supplementary variable, #side, could be used to vary the
  -- orientation of the interlocking area.  The createPuzzlePieces()
  -- handler would have to be modified to take account of this.
  --------------------------------------------------------------------
  
  if ilk(pEdgeList) <> #list then
    pEdgeList = []
  end if
  
  repeat while TRUE
    tilt  =  6 - random(11)
    slant =  6 - random(11)
    angle =  6 - random(11)
    curve = 14 + random(11)
    edge  = [#tilt: tilt, #slant: slant, #angle: angle, #curve: curve]
    
    if not pEdgeList.getPos(edge) then
      -- <edge> describes a unique curve
      -- edge[#side] = random(2) - 1 -- TRUE or FALSE
      pEdgeList.append(edge)
      if listP(topsList) then
        topsList[column] = edge
      end if
      exit repeat
    end if
  end repeat
  
  return edge
end randomEdge