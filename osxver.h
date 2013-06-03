/* 
osxver.h:
Created:06-01-2013
Author: McUsr

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*/
#ifndef _OSXVER_H_
#define _OSXVER_H_

struct osver {
	int minor;
	int sub;
} ;
typedef struct osver osxver ;
void macosx_ver(char *darwinversion, osxver *osxversion ) ;
char *osversionString(void) ;


#endif
