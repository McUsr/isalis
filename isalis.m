/***********************************************************************
 Name:	 isalis
 Created: 05-21-2013
 Author:  McUsr
 
 Usage:   
 Returns posix path of original item for file argument to stdout, 
 and sets exit code to zero, exits with 1 as exit code if it wasn't an
 alias.

 Thanks for teasing, code-examples  and comments from:
 	Shane Stanley and DJ Bazzie Wazzie
 
 Source:
 http://jongampark.wordpress.com/2008/12/23/resolving-aliases-using-cocoa/
 
 Command line to compile:
 gcc -Os -I/System/Library/Frameworks/CoreFoundation.framework/Versions/A/Headers/ -o isalis isalis.m -lobjc  -framework CoreFoundation -framework Cocoa
 
 DISCLAIMER
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 fileURLWithPath: bruke denne, men encode any blanks first.

 Then there is the toll-free bridging,
 And I have to return the bookmark data that is a path, as a posix path.

 */

#import <Foundation/Foundation.h>
#include <unistd.h>
#include <string.h>
#include <getopt.h>
#include <sys/param.h>
#include <sys/stat.h>
#include <stdlib.h>


/*
#include <CFNumber.h>
#include <CFURL.h>
*/
#define REPORT 			0x01
#define VERBOSITY 		0x02
#define BROKEN_LINKS 	0x04


#define ALL_WELL		0
#define NO_ALIAS		1
#define USER_ERROR		2
#define BROKEN_ALIAS	3
#define INTERNAL_ERR	4


size_t MAX_PATH;
static void usage(void) ;
static void version(void) ;
static void copyright(void) ;


static Boolean okFilename(char *fn) ;
static int analyze_bookmark( char *candidate,char delim,size_t slen, UInt8 oflags) ;
static struct option longopts[] = {
	{"help", no_argument, NULL, 'h'},
	{"usage", no_argument, NULL, 'u'},
	{"normal", no_argument, NULL, 'n'},
	{"copyright", no_argument, NULL, 'c'},
	{"version", no_argument, NULL, 'V'},
	{"delimiter", required_argument,NULL, 'd'},
    {"report",no_argument,NULL, 'r'},
   {"verbose",no_argument,NULL, 'v' },
	{"broken", no_argument, NULL, 'b'},
	{NULL, 0, NULL, 0},
};

int main (int argc, char **argv) {
	UInt8 	o_flags			= 0 ;
	size_t 	slen			= 0;	
    int 	cmd_err 		= EXIT_SUCCESS ;
	
	Boolean	redir			= (Boolean)(!isatty(STDIN_FILENO)),
			multiple		= NO;

	
	MAX_PATH= (size_t) pathconf(".",_PC_PATH_MAX) ;
	
	if (argc < 2 && redir == NO ) {
		usage() ;
		exit(USER_ERROR) ;
	}
	setbuf(stdout,NULL) ;
	
    extern int optind ;
	int	ch;
	char field_sep	= '\t';
			
	while ((ch = getopt_long(argc, argv, "huncVd:rvb", longopts,NULL )) != -1) {
		switch (ch) {
			case 'h':
				usage() ;
				exit(0) ;
			case 'u':
				usage() ;
				exit(0) ;
			case 'n':
				break;
			case 'c':
				copyright();
				exit(0) ;
			case 'V':
				version() ;
				exit(0);
			case 'd':
				field_sep = ((char)optarg[0]);
				break;	
			case 'r':
				o_flags |= REPORT ; 
				break;
			case 'v':
				o_flags |= VERBOSITY ; 
				break;
			case 'b':
				o_flags |= BROKEN_LINKS ; 
				break;
		}
	}
	if (optind<(argc-1) || redir == YES )  {
		multiple = YES;
	} else if (optind<argc) 
		multiple = NO ;
	else {
		usage() ;
		exit(USER_ERROR) ;
	}

	if (multiple == NO ) {
		if ((slen=strlen(argv[optind])) >= MAX_PATH ) {
			fprintf(stderr,"isalis: Pathname too long\n");
			exit(USER_ERROR) ;
		} else {
			
			if (okFilename(argv[optind]) == YES ) {
				cmd_err = analyze_bookmark(argv[optind],field_sep,slen,o_flags );
			} else if (o_flags & VERBOSITY ) {
					fprintf(stdout,"%s\n",argv[optind]);
			}
			exit(cmd_err) ;
		}
	} else if (multiple == YES ) {
		int final_code;
		if (redir == YES ) {
			char *buf = malloc( (size_t) MAX_PATH );
			if (buf == NULL ) {
				fprintf(stderr,"isalis %s: error during malloc\n",__PRETTY_FUNCTION__);
				exit(INTERNAL_ERR);
			}
			while((buf=fgets(buf,MAX_PATH+1,stdin))!=NULL) {
				buf[strlen(buf)-1] = '\0'  ;
				if ( buf )
				if (okFilename(buf) == YES ) {
					cmd_err = analyze_bookmark(buf,field_sep,slen,o_flags );
					final_code = (cmd_err == INTERNAL_ERR ) ?  INTERNAL_ERR  : ALL_WELL  ;
				} else if (o_flags & VERBOSITY ) {
					fprintf(stdout,"%s\n",buf);
				}
			}
			free(buf) ;
			buf=NULL ;
			exit(final_code) ;
		} else {
			int last_arg = argc -1 ;
			
			while ( optind < last_arg ) {
				if (okFilename(argv[optind++]) == YES ) {
					cmd_err = analyze_bookmark(argv[optind],field_sep,slen,o_flags );
					final_code = (cmd_err == INTERNAL_ERR ) ?  INTERNAL_ERR  : ALL_WELL  ;
				} else if (o_flags & VERBOSITY ) {
					fprintf(stdout,"%s\n",argv[optind] );
				}
			}
			exit(final_code) ;
		}
	}
}

static Boolean okFilename(char *fn) {
	struct stat buf;
		// removes those char's from the end of a file name for that we have 
		// gotten a "pretty ls- listing as input.
		// we -don't handle long ls listings very well...
	if ( fn[strlen(fn)-1] == '@' ) {
		fn[strlen(fn)-1]= '\0' ;
	}
	if (  fn[strlen(fn)-1] == '*' ) {
		fn[strlen(fn)-1]= '\0' ;
	}
	if (strlen(fn) == 2 && (!strcmp( fn,".." ))) return NO ;
		// Check that we aren't dealing with a dot-file.
	if ( fn[0] != '.' || ( fn[0] == '.' && strlen(fn) > 1 && ( fn[1] == '.' ||  fn[1] == '/')))  {
			// dotfiles starts with a '.' but if the next char is another '.' or '/' then its a relative path.
		if (lstat(fn, &buf) < 0) return NO ;

		if (S_ISREG(buf.st_mode))
			return YES ;
		else if (S_ISDIR(buf.st_mode))
			return YES ;
		else 
			return NO;
	} else {
		return NO ;
	}
}
static char *full_absolute_path( char **orig_path, size_t orig_len, size_t max_path_len )
{
		// room for improvements.
	char msg_buf[80],*new_ptr = malloc(max_path_len+1);
	if (new_ptr == NULL ) {
		sprintf(msg_buf,"%s couldn't allocate mem for realpath\n",__PRETTY_FUNCTION__);
		perror(msg_buf);
		exit(INTERNAL_ERR);
	}
	new_ptr=realpath(*orig_path, new_ptr);
	if (strlen(new_ptr)!= orig_len) {
		free(*orig_path);
		*orig_path = new_ptr ;
	} else {
		free(new_ptr);
		new_ptr = NULL ;
	}
	return *orig_path ;
}


static int analyze_bookmark( char *candidate,char delim, size_t slen, UInt8 oflags) {
	int notFound= NO_ALIAS;
	char *pathstr = NULL;
	pathstr=strdup(candidate) ;
	
	pathstr =full_absolute_path(&pathstr,strlen(pathstr),PATH_MAX );
	
	CFStringRef urlString = NULL;
	urlString = CFStringCreateWithBytes(kCFAllocatorDefault, (UInt8 *)pathstr, strlen(pathstr), kCFStringEncodingUTF8, FALSE);
	CFURLRef url = NULL;
	url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, urlString, kCFURLPOSIXPathStyle, TRUE);
	
    if (url != NULL) {
		CFBooleanRef isalias  = kCFBooleanFalse ; 
		CFErrorRef err;
		err=noErr ;
		if ( CFURLCopyResourcePropertyForKey ( url,kCFURLIsAliasFileKey , &isalias, &err) == true ) {
			
	        if (CFBooleanGetValue(isalias) == YES  && err == noErr) {
				
				Boolean isStale;
				isStale=NO;
				CFDataRef bkMrk;
				bkMrk  = CFURLCreateBookmarkDataFromFile(kCFAllocatorDefault , url, &err );
				if ( err == noErr ) {
					CFURLRef resolvedUrl;
					resolvedUrl = NULL ; 
					
					resolvedUrl =CFURLCreateByResolvingBookmarkData(kCFAllocatorDefault, bkMrk,
									(kCFBookmarkResolutionWithoutMountingMask|	kCFBookmarkResolutionWithoutUIMask), NULL, NULL, &isStale, &err) ;	
					CFRelease(bkMrk) ;	
		            if ( err == noErr && resolvedUrl != NULL ) {
						UInt8 *buf = malloc((size_t)MAX_PATH+1) ;	
						if (buf != NULL ) {
							
							if (CFURLGetFileSystemRepresentation(resolvedUrl, YES, buf,MAX_PATH)==YES ) {
								notFound=ALL_WELL;
								if (!oflags) {
									fprintf(stdout,"%s\n",(char *)buf) ;
									fflush(stdout) ;
								} else if (oflags & (REPORT|VERBOSITY) )  {
									fprintf(stdout,"%s%c%s\n",candidate,delim,(char *)buf) ;
									fflush(stdout) ;
								}	
		               			CFRelease(resolvedUrl);
							} 
							free(buf) ;
						} else {
							fprintf(stderr,"isalis %s: Error during malloc\n",__PRETTY_FUNCTION__ );
							exit(INTERNAL_ERR) ;
						}
					} else if (err != noErr ) {
						if ( oflags & BROKEN_LINKS ) {
							fprintf(stdout,"%s\n",candidate) ;
							fflush(stdout) ;
							notFound=ALL_WELL;
						} else if (oflags ) {
							fprintf(stderr,"%s%cBROKEN ALIAS\n",candidate,delim) ;
							notFound=BROKEN_ALIAS;
						}
					}
				}
			} else if ( (oflags & VERBOSITY)!= 0 ) {
				fprintf(stdout,"%s\n",candidate) ;
							fflush(stdout) ;
			}
			
			
		} else if ((oflags & VERBOSITY) != 0 )  {
			fprintf(stdout,"%s\n",candidate) ;
			fflush(stdout) ;
		}
		CFURLClearResourcePropertyCache(url) ;
			
		CFRelease(url);
	} else {
		fprintf(stderr, "furl for %s == NULL\n",candidate ) ;
	}
	free(pathstr) ;
	CFRelease(urlString);
    return notFound;
}

static void version(void) {
	fprintf(stderr,"isalias version 1.0 © 2013 Copyright McUsr and put into Public Domain under GNU Gpl.\n") ;
}

static void copyright(void) {
	version() ;
}

static void usage(void) {
	fprintf(stderr,"Usage: isalis [options] [1..n file arguments or from stdin; one file  on each line.]\n");
	fprintf(stderr,"\n");
	fprintf(stderr,"Options\n");
	fprintf(stderr,"-------\n");
	fprintf(stderr,"  All output options are mutually exclusive, the last one takes effect.\n");
	fprintf(stderr,"\n");
	fprintf(stderr,"  isalis [- -huncVdrvb]\n");
	fprintf(stderr,"  isalis [ --help,--usage,--normal,--copyright\n");
	fprintf(stderr,"           --version,--delimiter,--report,--verbose,--broken ]\n");
	fprintf(stderr,"\n");
	fprintf(stderr,"Examples\n");
	fprintf(stderr,"--------\n");
	fprintf(stderr,"  isalis file1\n");
	fprintf(stderr,"  Returns the original item of file1 if it exists, great for the cd command.\n");
	fprintf(stderr,"\n");
	fprintf(stderr,"  cat flist |isalis \n");
	fprintf(stderr,"  prints the paths of the original items given from any aliases from stdin\n");
	fprintf(stderr,"\n");
	fprintf(stderr,"  cat flist |isalis -r\n");
	fprintf(stderr,"  Prints the original items of all aliases found, or broken, to the right\n");
	fprintf(stderr,"  of the filename.\n");
	fprintf(stderr,"\n");
	fprintf(stderr,"  cat flist | isalis  -v\n");
	fprintf(stderr,"  Prints all inspected filenames, those that are aliases gets their path\n");
	fprintf(stderr,"  or BROKEN displayed in  column to the right.\n");
	fprintf(stderr,"\n");
	fprintf(stderr,"  isalis --broken f1 f2 f3 f4 ...\n");
	fprintf(stderr,"  prints all broken aliases found in the files given on the command line.\n");
	fprintf(stderr,"\n");
	fprintf(stderr,"Explanation of the options\n");
	fprintf(stderr,"--------------------------\n");
	fprintf(stderr,"  -h,--help:      Shows this help and quits.\n");
	fprintf(stderr,"\n");
	fprintf(stderr,"  -u,--usage:     Shows this help and quits.\n");
	fprintf(stderr,"\n");
	fprintf(stderr,"  -n,--normal:    Shows the alias if found in file-argument given.\n");
	fprintf(stderr,"                  This is the  same as giving no option.\n");
	fprintf(stderr,"  -d,--delimiter: Sets the delimiter, for separating path and alias.\n");
	fprintf(stderr,"  -c,--copyright: Prints out a copyright notice.\n");
	fprintf(stderr,"  -V,--version:   Prints out the version of isalis.\n");
	fprintf(stderr,"\n");
	fprintf(stderr,"  -r,--report:    Prints a report containing every alias found in the file\n");
	fprintf(stderr,"                  arguments, and if they are bad.  Broken aliases are\n");
	fprintf(stderr,"				  printed onto stderr.\n");
	fprintf(stderr,"                  ----------------------------------------------------------------\n");
	fprintf(stderr,"                  [original filename][ tab (\\t)][ the alias  (or   BROKEN ALIAS)] \n");
	fprintf(stderr,"\n");
	fprintf(stderr,"  -v,--verbose:   Normal files found  are added on separate lines crohnologically\n");
	fprintf(stderr,"                  with the output from --report.\n");
	fprintf(stderr,"                  ---------------------------------------------------------------\n");
	fprintf(stderr,"                  [original filename][ tab (\\t)][ the alias  (or   BROKEN ALIAS)] \n");
	fprintf(stderr,"                  [regular filename ]\n");
	fprintf(stderr,"                  [...]\n");
	fprintf(stderr,"\n");
	fprintf(stderr,"  -b,--broken:    Shows original filenames of all broken aliases to stdout.\n");
	fprintf(stderr,"                  And nothing more.\n");
	fprintf(stderr,"                  ---------------------------------------------------------------\n");
	fprintf(stderr,"                  [original filename]\n");
	fprintf(stderr,"\n");
	fprintf(stderr,"Error codes\n");
	fprintf(stderr,"-----------\n");
	fprintf(stderr,"Single file mode\n");
	fprintf(stderr,"\n");
	fprintf(stderr,"    0: An alias that was correct was found.\n");
	fprintf(stderr,"    1: An alias wasn't found.\n");
	fprintf(stderr,"    2: Is an operator error.\n");
	fprintf(stderr,"    3: Is a broken alias.\n");
	fprintf(stderr,"    4: Internal program error.\n");
	fprintf(stderr,"\n");
	fprintf(stderr,"Multi file mode (Batch).\n");
	fprintf(stderr,"    0: At least one alias file was found and none with a broken alias was found.\n");
	fprintf(stderr,"    1: Not a single alias file was found.\n");
	fprintf(stderr,"    3: At least one alias that was broke were found.\n");
	fprintf(stderr,"    4: Internal program error.\n");
}
