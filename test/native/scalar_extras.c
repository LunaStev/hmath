/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_scalar_extras.h"
#include "hmath_error.h"
#include <assert.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
int main(void) {
    hmath_value *selector=NULL,*other=NULL,*value=NULL,*result=NULL,*item=NULL;
    hmath_value *a=NULL,*b=NULL,*c=NULL,*negative=NULL;
    assert(hmath_init()==HMATH_OK);
    assert(hmath_trigonometry_c_sin(NULL,&selector)==HMATH_OK);
    assert(hmath_value_complex_f32(NULL,0.25f,0.5f,&value)==HMATH_OK);
    assert(hmath_trigonometry_complex_function(NULL,selector,value,&result)==HMATH_OK);
    int kind=0,dtype=0;size_t count=0;
    assert(hmath_value_info(result,&kind,&dtype,&count)==HMATH_OK && kind==1 && dtype==5);
    float real=0,imaginary=0;
    assert(hmath_value_get_f32(result,&real,&imaginary)==HMATH_OK);
    assert(isfinite(real) && isfinite(imaginary));
    hmath_value_release(result);hmath_value_release(value);
    assert(hmath_complex_sin(NULL,&other)==HMATH_OK);
    hmath_value *unchanged=(hmath_value *)(uintptr_t)1;
    assert(hmath_trigonometry_complex_function(NULL,other,selector,&unchanged)==HMATH_INVALID_ARGUMENT);
    assert(unchanged==(hmath_value *)(uintptr_t)1);
    hmath_value_release(other);hmath_value_release(selector);
    assert(hmath_value_f64(NULL,-0.0,&a)==HMATH_OK);
    assert(hmath_value_f64(NULL,-2.5,&b)==HMATH_OK);
    assert(hmath_special_sf_result(NULL,a,b,&result)==HMATH_OK);
    assert(hmath_special_sf_value(NULL,result,&item)==HMATH_OK);
    double x=1,y=1;assert(hmath_value_get_f64(item,&x,&y)==HMATH_OK && signbit(x));
    hmath_value_release(item);
    assert(hmath_special_sf_error(NULL,result,&item)==HMATH_OK);
    assert(hmath_value_get_f64(item,&x,&y)==HMATH_OK && x==-2.5);
    hmath_value_release(item);hmath_value_release(result);hmath_value_release(a);hmath_value_release(b);
    assert(hmath_value_integer(NULL,"1234567890123456789012345678901234567890",&a)==HMATH_OK);
    assert(hmath_value_integer(NULL,"0",&b)==HMATH_OK);
    assert(hmath_value_integer(NULL,"2469135780246913578024691357802469135780",&c)==HMATH_OK);
    assert(hmath_numbertheory_linear_diophantine(NULL,a,b,c,&result)==HMATH_OK);
    assert(hmath_value_info(result,&kind,&dtype,&count)==HMATH_OK && kind==5 && count==4);
    assert(hmath_value_item(NULL,result,0,&item)==HMATH_OK);
    hmath_value_release(result);char *num=NULL,*den=NULL;
    assert(hmath_value_get_exact(item,&num,&den)==HMATH_OK && strcmp(num,"2")==0);
    hmath_value_string_free(num);hmath_value_string_free(den);hmath_value_release(item);
    assert(hmath_value_index(NULL,-1,&negative)==HMATH_OK);
    assert(hmath_numbertheory_partitions(NULL,negative,&unchanged)==HMATH_MATH_ERROR);
    assert(unchanged==(hmath_value *)(uintptr_t)1);
    hmath_math_error error;assert(hmath_last_math_error(&error));
    assert(hmath_runtime_shutdown()==HMATH_BUSY);
    hmath_value_release(a);hmath_value_release(b);hmath_value_release(c);hmath_value_release(negative);
    assert(hmath_runtime_shutdown()==HMATH_OK);
    puts("Scalar extras C precision, raw SFResult, exact tuples, errors and lifetime contracts passed.");
    return 0;
}
