require 'narray'

class Array
  def seek(dec) # accepts [0,1) (not including 1)
    fetch((size*dec).to_int)
  end
  def position(el) # returns position in (0,1) of "centre" of element (think of array as discrete dimension)
    (2*index(el) + 1) / (2*size)
  end
  def like(el, ary) # returns 
    seek(ary.position(el))
  end
  def p(num)
    map{|el|el+num}
  end
  def x(num)
    map{|el|el*num}
  end
  def e(num)
    + p(num)
  end
end
