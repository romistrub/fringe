/* Copyright (c) 2007 Scott Lembcke
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
 
#include <stdlib.h>
#include "chipmunk.h"

#include "ruby.h"
#include "rb_chipmunk.h"

ID id_body;

VALUE m_cpShape;
VALUE c_cpCircleShape;
VALUE c_cpSegmentShape;
VALUE c_cpPolyShape;
VALUE c_cpSegmentQueryInfo;

//c_cpSegmentQueryInfo
GETTER_TEMPLATE(SQINFO, c_cpSegmentQueryInfo, cpSegmentQueryInfo)

static cpSegmentQueryInfo * cpSegmentQueryInfoAlloc() 
{
  return malloc(sizeof(cpSegmentQueryInfo));
}

static cpSegmentQueryInfo * cpSegmentQueryInfoInit(cpSegmentQueryInfo * self, 
  cpShape * shape, cpFloat t, cpVect n) 
{
  self->shape = shape;
  self->t     = t;
  self->n     = n;
  return self;
}

static VALUE
rb_cpSegmentQueryInfoAlloc(VALUE klass)
{
  struct cpSegmentQueryInfo * info = cpSegmentQueryInfoAlloc();  
  return Data_Wrap_Struct(klass, NULL, free, info);
}

static VALUE
rb_cpSeqmentQueryInfoInitialize(VALUE self, VALUE shape, VALUE t, VALUE n)
{
  struct cpSegmentQueryInfo * info;
  info        = SQINFO(self);
  cpSegmentQueryInfoInit(info, SHAPE(shape), NUM2DBL(t), *VGET(n));
  return self;
}

static VALUE
rb_cpSeqmentQueryInfoGetShape(VALUE self) 
{
  cpShape * shape = SQINFO(self)->shape;
  if (!shape) return Qnil;  
  //XXX: technically speaking, this is wrong... :p. 
  // It's hard to wrap, though...
  return (VALUE) SQINFO(self)->shape->data;
  // return Qtrue;
  // return Data_Wrap_Struct(c_cpShape, 0, cpShapeFree, SQINFO(self)->shape);
}

static VALUE
rb_cpSeqmentQueryInfoGetT(VALUE self) 
{
  return rb_float_new(SQINFO(self)->t);
}

static VALUE
rb_cpSeqmentQueryInfoGetN(VALUE self) 
{  
  return VNEW(SQINFO(self)->n);
}

static VALUE
rb_cpSeqmentQueryInfoHitPoint(VALUE self, VALUE start, VALUE end)
{
  return VNEW(cpSegmentQueryHitPoint(*VGET(start), *VGET(end), *SQINFO(self)));
}

static VALUE
rb_cpSeqmentQueryInfoHitDist(VALUE self, VALUE start, VALUE end)
{
  return rb_float_new(cpSegmentQueryHitDist(*VGET(start), *VGET(end), *SQINFO(self)));
}


//c_cpShape
static VALUE
rb_cpShapeGetBody(VALUE self)
{
	return rb_ivar_get(self, id_body);
}

static VALUE
rb_cpShapeSetBody(VALUE self, VALUE body)
{
	SHAPE(self)->body = BODY(body);
	rb_ivar_set(self, id_body, body);
	
	return body;
}

static VALUE
rb_cpShapeGetCollType(VALUE self)
{
	return rb_iv_get(self, "collType");
}

static VALUE
rb_cpShapeSetCollType(VALUE self, VALUE val)
{
	VALUE col_type = rb_obj_id(val);
	rb_iv_set(self, "collType", val);
	SHAPE(self)->collision_type = NUM2UINT(col_type);
	
	return val;
}

static VALUE
rb_cpShapeGetGroup(VALUE self)
{
	return rb_iv_get(self, "group");
}

static VALUE
rb_cpShapeSetGroup(VALUE self, VALUE val)
{
  VALUE group_type = rb_obj_id(val);
  rb_iv_set(self, "group", val);
  
  if (val == rb_intern("no_group")) {
    SHAPE(self)->group = CP_NO_GROUP;
  } else {   
    SHAPE(self)->group = NUM2UINT(group_type);
  } 
	
  return val;
}

static VALUE
rb_cpShapeGetLayers(VALUE self)
{
  if(SHAPE(self)->layers == CP_ALL_LAYERS) { 
    return rb_intern("all_layers");
  }  
  return UINT2NUM(SHAPE(self)->layers);
}

static VALUE
rb_cpShapeSetLayers(VALUE self, VALUE layers)
{
  if (layers == rb_intern("all_layers")) { 
    SHAPE(self)->layers = CP_ALL_LAYERS;
	} else { 
    SHAPE(self)->layers = NUM2UINT(layers);
  }	
	return layers;
}

static VALUE
rb_cpShapeGetBB(VALUE self)
{
	cpBB *bb = malloc(sizeof(cpBB));
	*bb = SHAPE(self)->bb;
	return Data_Wrap_Struct(c_cpBB, NULL, free, bb);
}

static VALUE
rb_cpShapeCacheBB(VALUE self)
{
	cpShape *shape = SHAPE(self);
	cpShapeCacheBB(shape);
	
	return rb_cpShapeGetBB(self);
}

static VALUE
rb_cpShapeGetElasticity(VALUE self)
{
	return rb_float_new(SHAPE(self)->e);
}

static VALUE
rb_cpShapeGetFriction(VALUE self)
{
	return rb_float_new(SHAPE(self)->u);
}


static VALUE
rb_cpShapeSetElasticity(VALUE self, VALUE val)
{
	SHAPE(self)->e = NUM2DBL(val);
	return val;
}

static VALUE
rb_cpShapeSetFriction(VALUE self, VALUE val)
{
	SHAPE(self)->u = NUM2DBL(val);
	return val;
}

static VALUE
rb_cpShapeGetSurfaceV(VALUE self)
{
	return VWRAP(self, &SHAPE(self)->surface_v);
}

static VALUE
rb_cpShapeSetSurfaceV(VALUE self, VALUE val)
{
	SHAPE(self)->surface_v = *VGET(val);
	return val;
}

static VALUE
rb_cpShapeResetIdCounter(VALUE self)
{
	cpResetShapeIdCounter();
	return Qnil;
}

static VALUE
rb_cpShapeGetData(VALUE self)
{
  return (VALUE) (SHAPE(self)->data);
}


static VALUE
rb_cpShapeGetSensor(VALUE self)
{
  int bool = (SHAPE(self)->sensor);  
  return bool ? Qtrue : Qfalse;
}

static VALUE
rb_cpShapeSetSensor(VALUE self, VALUE val)
{
  int bool = ((val == Qnil) || (val == Qfalse)) ? 0 :  1;
  SHAPE(self)->sensor = bool;    
  return val;
}

static VALUE 
rb_cpShapePointQuery(VALUE self, VALUE point) {  
  int bool = cpShapePointQuery(SHAPE(self), *VGET(point));
  return bool ? Qtrue : Qfalse;
}

// Shape/segment query
static VALUE
rb_cpShapeSegmentQuery(VALUE self, VALUE a, VALUE b) 
{
  cpSegmentQueryInfo * info = cpSegmentQueryInfoAlloc();
  int bool = cpShapeSegmentQuery(SHAPE(self), *VGET(a), *VGET(b), info);
  if (bool) {  
    return Data_Wrap_Struct(c_cpSegmentQueryInfo, NULL, free, info);
  } else {
    return Qnil;
  } 
}


//cpCircle
static VALUE
rb_cpCircleAlloc(VALUE klass)
{
	cpCircleShape *circle = cpCircleShapeAlloc();
	return Data_Wrap_Struct(klass, NULL, cpShapeFree, circle);
}

static VALUE
rb_cpCircleInitialize(VALUE self, VALUE body, VALUE radius, VALUE offset)
{
	cpCircleShape *circle = (cpCircleShape *)SHAPE(self);
	
	cpCircleShapeInit(circle, BODY(body), NUM2DBL(radius), *VGET(offset));
	circle->shape.data = (void *)self;
	circle->shape.collision_type = Qnil;

	rb_ivar_set(self, id_body, body);
	
	return self;
}



//cpSegment
static VALUE
rb_cpSegmentAlloc(VALUE klass)
{
	cpSegmentShape *seg = cpSegmentShapeAlloc();
	return Data_Wrap_Struct(klass, NULL, cpShapeFree, seg);
}

static VALUE
rb_cpSegmentInitialize(VALUE self, VALUE body, VALUE a, VALUE b, VALUE r)
{
	cpSegmentShape *seg = (cpSegmentShape *)SHAPE(self);
	
	cpSegmentShapeInit(seg, BODY(body), *VGET(a), *VGET(b), NUM2DBL(r));
	seg->shape.data = (void *)self;
	seg->shape.collision_type = Qnil;

	rb_ivar_set(self, id_body, body);
	
	return self;
}



//cpPoly
static VALUE
rb_cpPolyAlloc(VALUE klass)
{
	cpPolyShape *poly = cpPolyShapeAlloc();
	return Data_Wrap_Struct(klass, NULL, cpShapeFree, poly);
}

static VALUE
rb_cpPolyInitialize(VALUE self, VALUE body, VALUE arr, VALUE offset)
{
	cpPolyShape *poly = (cpPolyShape *)SHAPE(self);
	
	Check_Type(arr, T_ARRAY);
	int numVerts = RARRAY_LEN(arr);
	VALUE *ary_ptr = RARRAY_PTR(arr);
	cpVect verts[numVerts];
	
	for(int i=0; i<numVerts; i++)
		verts[i] = *VGET(ary_ptr[i]);
	
	cpPolyShapeInit(poly, BODY(body), numVerts, verts, *VGET(offset));
	poly->shape.data = (void *)self;
	poly->shape.collision_type = Qnil;

	rb_ivar_set(self, id_body, body);
	
	return self;
}






void
Init_cpShape(void)
{
	id_body = rb_intern("body");
	
	m_cpShape = rb_define_module_under(m_Chipmunk, "Shape");
	rb_define_attr(m_cpShape, "obj", 1, 1);
	
	rb_define_method(m_cpShape, "body", rb_cpShapeGetBody, 0);
	rb_define_method(m_cpShape, "body=", rb_cpShapeSetBody, 1);
	
	rb_define_method(m_cpShape, "collision_type", rb_cpShapeGetCollType, 0);
	rb_define_method(m_cpShape, "collision_type=", rb_cpShapeSetCollType, 1);
	
	rb_define_method(m_cpShape, "group", rb_cpShapeGetGroup, 0);
	rb_define_method(m_cpShape, "group=", rb_cpShapeSetGroup, 1);
	
	rb_define_method(m_cpShape, "layers", rb_cpShapeGetLayers, 0);
	rb_define_method(m_cpShape, "layers=", rb_cpShapeSetLayers, 1);
	
	rb_define_method(m_cpShape, "bb", rb_cpShapeGetBB, 0);
	rb_define_method(m_cpShape, "cache_bb", rb_cpShapeCacheBB, 0);
	
	rb_define_method(m_cpShape, "e", rb_cpShapeGetElasticity, 0);
	rb_define_method(m_cpShape, "u", rb_cpShapeGetFriction, 0);
	
	rb_define_method(m_cpShape, "e=", rb_cpShapeSetElasticity, 1);
	rb_define_method(m_cpShape, "u=", rb_cpShapeSetFriction, 1);
		
  rb_define_method(m_cpShape, "surface_v"  , rb_cpShapeGetSurfaceV, 0);
	rb_define_method(m_cpShape, "surface_v=" , rb_cpShapeSetSurfaceV, 1);
  
  rb_define_method(m_cpShape, "data"       , rb_cpShapeGetData, 0);  
  /* 
  XXX: do we need data= ? Data is used internally, so perhaps what 
  chipmunk-ffi isdoing doesn't make sense here?
  */   
  rb_define_method(m_cpShape, "sensor"  , rb_cpShapeGetSensor, 0);
  rb_define_method(m_cpShape, "sensor?" , rb_cpShapeGetSensor, 0);
  rb_define_method(m_cpShape, "sensor=" , rb_cpShapeSetSensor, 1);
  
  rb_define_method(m_cpShape, "point_query" , rb_cpShapePointQuery, 1);
  rb_define_method(m_cpShape, "segment_query", rb_cpShapeSegmentQuery, 2);
  
  
	
	rb_define_singleton_method(m_cpShape, "reset_id_counter", rb_cpShapeResetIdCounter, 0);

	
	c_cpCircleShape = rb_define_class_under(m_cpShape, "Circle", rb_cObject);
	rb_include_module(c_cpCircleShape, m_cpShape);
	rb_define_alloc_func(c_cpCircleShape, rb_cpCircleAlloc);
	rb_define_method(c_cpCircleShape, "initialize", rb_cpCircleInitialize, 3);
	
	
	c_cpSegmentShape = rb_define_class_under(m_cpShape, "Segment", rb_cObject);
	rb_include_module(c_cpSegmentShape, m_cpShape);
	rb_define_alloc_func(c_cpSegmentShape, rb_cpSegmentAlloc);
	rb_define_method(c_cpSegmentShape, "initialize", rb_cpSegmentInitialize, 4);


	c_cpPolyShape = rb_define_class_under(m_cpShape, "Poly", rb_cObject);
	rb_include_module(c_cpPolyShape, m_cpShape);
	rb_define_alloc_func(c_cpPolyShape, rb_cpPolyAlloc);
	rb_define_method(c_cpPolyShape, "initialize", rb_cpPolyInitialize, 3);
  
  
  c_cpSegmentQueryInfo = rb_define_class_under(m_cpShape, 
    "SegmentQueryInfo", rb_cObject);
  rb_define_alloc_func(c_cpSegmentQueryInfo, rb_cpSegmentQueryInfoAlloc);
  rb_define_method(c_cpSegmentQueryInfo, "initialize",
    rb_cpSeqmentQueryInfoInitialize, 3);
    
  rb_define_method(c_cpSegmentQueryInfo, "shape", 
    rb_cpSeqmentQueryInfoGetShape, 0);
  rb_define_method(c_cpSegmentQueryInfo, "hit", 
    rb_cpSeqmentQueryInfoGetShape, 0);  
  rb_define_method(c_cpSegmentQueryInfo, "t", 
    rb_cpSeqmentQueryInfoGetT, 0);
  rb_define_method(c_cpSegmentQueryInfo, "n", 
    rb_cpSeqmentQueryInfoGetN, 0);
  rb_define_method(c_cpSegmentQueryInfo, "hit_point", 
    rb_cpSeqmentQueryInfoHitPoint, 2);    
  rb_define_method(c_cpSegmentQueryInfo, "hit_distance", 
    rb_cpSeqmentQueryInfoHitDist, 2);
  
}

