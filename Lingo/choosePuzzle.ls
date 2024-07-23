-- CHOOSE PUZZLE --

on beginSprite(me)
  if me.spriteNum = 1 then
    me.doPuzzle(3)
  end if
end beginSprite



on mouseUp(me)
  me.doPuzzle()
end mouseUp



on doPuzzle(me, sideCount)
  thisMember = sprite(me.spriteNum).member
  
  -- Hard coding
  bkgndSprite  = sprite(6)  
  imageChannel = 8
  theScript    = script("Puzzle Pieces")
  
  if not sideCount then
    -- Determine a random number of pieces
    sideCount = 1 + random(5)
  end if
  
  -- Erase any existing puzzle piece bitmaps
  i = the number of members of castLib 1
  repeat while i
    if member(i).type = #bitmap then
      erase member(i)
    else
      i = i - 1
      if member(i).type = #bitmap then
        erase member(i)
      end if
      
      exit repeat
    end if
    i = i - 1
  end repeat
  
  -- Create a new set of puzzle bitmaps
  no3D = the shiftDown
  data = theScript.createPuzzleData(thisMember, sideCount, 96, no3D)
  
  pieces = data.pieces
  edge   = data.edge
  border = data.border
  hCount = data.hCount
  vCount = data.vCount
  
  -- Attribute the appropriate image to the various sprites
  bkgndSprite.member = data.image
  topLeft = point(bkgndSprite.left, bkgndSprite.top) + border
  
  i = pieces.count
  repeat while i
    imageSprite        = sprite(imageChannel + i)
    imageSprite.member = pieces[i]
    
    i = i - 1
    columnAdjust       = (i mod hCount) * edge
    rowAdjust          = (i / hCount) * edge
    imageSprite.loc    = topLeft + [columnAdjust, rowAdjust]
  end repeat
end mouseUp