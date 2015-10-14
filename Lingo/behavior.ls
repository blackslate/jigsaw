property spriteNum

on mouseDown(me)
  sprite(spriteNum).locZ = the lastChannel
end

on mouseUp(me)
  sprite(spriteNum).locZ = spriteNum 
end mouseUp

on mouseUpOutside(me)
  sprite(spriteNum).locZ = spriteNum 
end mouseUpOutside