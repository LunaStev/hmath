/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_buffer.h"
#include "hmath_error.h"
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
typedef struct state {hmath_value *retained;hmath_value *io;int calls;} state;
static hmath_status region(const hmath_value *arguments,void *userdata,hmath_value **out,hmath_math_error *error) {
    (void)error;state *s=(state *)userdata;
    hmath_value *index=NULL,*value=NULL,*unit=NULL;
    hmath_status status=hmath_value_item(NULL,arguments,0,&s->retained);
    if(!status)status=hmath_value_index(NULL,1,&index);
    if(!status)status=hmath_value_integer(NULL,"1234567890123456789012345678901234567890",&value);
    if(!status)status=hmath_buffer_write_st_buffer(NULL,s->retained,index,value,&unit);
    if(!status)status=hmath_buffer_freeze_st_buffer(NULL,s->retained,out);
    hmath_value_release(index);hmath_value_release(value);hmath_value_release(unit);
    ++s->calls;return status;
}
static hmath_status pointer(const hmath_value *arguments,void *userdata,hmath_value **out,hmath_math_error *error) {
    (void)error;state *s=(state *)userdata;
    hmath_value *index=NULL,*value=NULL,*unit=NULL,*unchanged=(hmath_value *)(uintptr_t)1;
    hmath_status status=hmath_value_item(NULL,arguments,0,&s->retained);
    if(!status)status=hmath_value_index(NULL,0,&index);
    if(!status)status=hmath_value_f32(NULL,3.5f,&value);
    if(!status) {
        assert(hmath_buffer_read_io_buffer(NULL,s->io,index,&unchanged)==HMATH_BUSY);
        assert(unchanged==(hmath_value *)(uintptr_t)1);
        status=hmath_buffer_pointer_write(NULL,s->retained,index,value,&unit);
    }
    if(!status)status=hmath_buffer_pointer_read(NULL,s->retained,index,out);
    hmath_value_release(index);hmath_value_release(value);hmath_value_release(unit);
    ++s->calls;return status;
}
static hmath_status failure(const hmath_value *arguments,void *userdata,hmath_value **out,hmath_math_error *error) {
    (void)arguments;(void)userdata;(void)out;
    memset(error,0,sizeof *error);error->kind=HMATH_MATH_DOMAIN_ERROR;
    error->message="borrow callback failed";error->message_length=strlen(error->message);
    return HMATH_MATH_ERROR;
}
int main(void) {
    assert(hmath_init()==HMATH_OK);
    hmath_value *one=NULL,*two=NULL,*xs=NULL,*boxed=NULL,*callback=NULL,*result=NULL,*child=NULL,*index=NULL;
    assert(hmath_value_integer(NULL,"1",&one)==HMATH_OK);
    assert(hmath_value_integer(NULL,"2",&two)==HMATH_OK);
    const hmath_value *items[]={one,two};
    assert(hmath_value_list(NULL,items,2,&xs)==HMATH_OK);
    assert(hmath_buffer_lazy_boxed(NULL,xs,&boxed)==HMATH_OK);
    state s={NULL,NULL,0};
    assert(hmath_linear_callback(NULL,region,&s,&callback)==HMATH_OK);
    assert(hmath_buffer_run_st_buffer(NULL,boxed,callback,&result)==HMATH_OK && s.calls==1);
    hmath_value_release(callback);
    assert(hmath_buffer_boxed_values(NULL,result,&child)==HMATH_OK);
    hmath_value_release(result);assert(hmath_value_index(NULL,1,&index)==HMATH_OK);
    assert(hmath_value_item(NULL,child,1,&result)==HMATH_OK);hmath_value_release(child);
    char *numerator=NULL,*denominator=NULL;
    assert(hmath_value_get_exact(result,&numerator,&denominator)==HMATH_OK);
    assert(strcmp(numerator,"1234567890123456789012345678901234567890")==0);
    hmath_value_string_free(numerator);hmath_value_string_free(denominator);hmath_value_release(result);
    hmath_value *unchanged=(hmath_value *)(uintptr_t)1;
    assert(hmath_buffer_read_st_buffer(NULL,s.retained,index,&unchanged)==HMATH_INVALID_ARGUMENT);
    assert(unchanged==(hmath_value *)(uintptr_t)1);
    assert(hmath_buffer_st_active(NULL,s.retained,&result)==HMATH_OK);
    int alive=1;assert(hmath_value_get_boolean(result,&alive)==HMATH_OK && !alive);
    hmath_value_release(result);hmath_value_release(s.retained);s.retained=NULL;
    hmath_value *initial=NULL,*count=NULL;
    assert(hmath_value_f32(NULL,-0.0f,&initial)==HMATH_OK);
    assert(hmath_value_index(NULL,2,&count)==HMATH_OK);
    assert(hmath_buffer_new_io_buffer(NULL,count,initial,&s.io)==HMATH_OK);
    assert(hmath_linear_callback(NULL,pointer,&s,&callback)==HMATH_OK);
    assert(hmath_buffer_with_io_buffer(NULL,s.io,callback,&result)==HMATH_OK && s.calls==2);
    float real=0,imaginary=0;assert(hmath_value_get_f32(result,&real,&imaginary)==HMATH_OK && real==3.5f);
    hmath_value_release(result);hmath_value_release(callback);
    assert(hmath_buffer_pointer_read(NULL,s.retained,index,&unchanged)==HMATH_INVALID_ARGUMENT);
    assert(hmath_buffer_pointer_address(NULL,s.retained,&unchanged)==HMATH_INVALID_ARGUMENT);
    assert(unchanged==(hmath_value *)(uintptr_t)1);hmath_value_release(s.retained);
    assert(hmath_linear_callback(NULL,failure,NULL,&callback)==HMATH_OK);
    assert(hmath_buffer_with_io_buffer(NULL,s.io,callback,&unchanged)==HMATH_MATH_ERROR);
    assert(unchanged==(hmath_value *)(uintptr_t)1);
    hmath_math_error error;assert(hmath_last_math_error(&error) && error.kind==HMATH_MATH_DOMAIN_ERROR);
    assert(error.message_length==22 && memcmp(error.message,"borrow callback failed",22)==0);
    hmath_value_release(callback);
    assert(hmath_buffer_read_io_buffer(NULL,s.io,index,&result)==HMATH_OK);
    hmath_value_release(result);
    assert(hmath_buffer_freeze_io_buffer(NULL,s.io,&result)==HMATH_OK);
    hmath_value *none=NULL,*copy=NULL;
    assert(hmath_value_none(NULL,&none)==HMATH_OK);
    assert(hmath_buffer_thaw_io_buffer(NULL,none,result,&copy)==HMATH_OK);
    hmath_value_release(result);hmath_value_release(s.io);hmath_value_release(none);
    assert(hmath_buffer_read_io_buffer(NULL,copy,index,&result)==HMATH_OK);
    hmath_value_release(copy);hmath_value_release(result);
    assert(hmath_runtime_shutdown()==HMATH_BUSY);
    hmath_value_release(initial);hmath_value_release(count);hmath_value_release(index);
    hmath_value_release(one);hmath_value_release(two);hmath_value_release(xs);hmath_value_release(boxed);
    assert(hmath_runtime_shutdown()==HMATH_OK);
    puts("Buffer C exact/scoped ST, original pointer borrows, callback errors, reentry and owned copying contracts passed.");
    return 0;
}
