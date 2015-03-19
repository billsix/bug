// Copyright 2014,2015 - William Emerison Six
//  All rights reserved
//  Distributed under LGPL 2.0 or Apache 2.0

#include <stdio.h>
#include <stdlib.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <ctype.h>

#include <errno.h>

#define SIZE_OF_INPUT_BUFFER 10000
#define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]))

// file descriptor for the input
int inputfd;
// file descriptor where the output will go
int outputfd;

// write to outputfd or die
ssize_t xwrite(const void *buf, size_t count)
{
  ssize_t result;
  // TODO  check for EAGAIN
  if( (result = write(outputfd,buf,count)) == -1)
    {
      puts("Error writing to the output file");
      printf("%zd\n", count);
      exit(1);
    }
  return result;
}


int main(int argc, char** argv)
{
  if(argc < 2)
    {
      puts("Usage: bug-gscpp inputfile outputfile");
      exit(1);
    }
  // open input file
  {
    char* programName = argv[1];  
    inputfd = open(programName, O_RDONLY);
    if(inputfd == -1)
      {
	// TODO:  Handle errnos
	printf("Error: unable to open input file %s, errno %d \n",programName, errno);
	exit(1);
      }
  }
  // open output file
  {
    char* outputFileName = argv[2];
    outputfd = creat(outputFileName, S_IRWXU);
    if(outputfd == -1)
      {
	// TODO:  Handle errnos
	printf("Error: unable to open output file %s, errno %d \n",outputFileName, errno);
	exit(1);
      }
  }
  // read the input file into a buffer, translate special characters
  // like "[]{}||" into valid scheme code, write to output file
  {
    char buf[SIZE_OF_INPUT_BUFFER];
    ssize_t bytesRead = 0;
    // TODO handle read errors

    
    while(bytesRead = read(inputfd, buf, SIZE_OF_INPUT_BUFFER), 
	  bytesRead > 0)
      {
	for(int i = 0; i < bytesRead; i++)
	  {
	    void handleLambda(char * buf, int * i);
	    switch(buf[i]){
	    case '|':
	    case ']':
	      xwrite(")", 1);
	      break;
	    case '}':
	      xwrite("))", 2);
	      break;
	    case '[':
	      handleLambda(buf,&i);
	      break;
	    case '{':
	      handleLambda(buf,&i);
	      xwrite("(", 1);
	      break;
	    default:
	      xwrite(&buf[i], 1);
	    }
	  }
      }
    close(outputfd);
  }
}

void handleLambda(char * buf, int * i)
{
  static const char text[] = "(lambda ";
  xwrite(text,ARRAY_SIZE(text) - 1);
  // skip whitespace
  {
    (*i)++;
    while(isspace(buf[*i]))
      {
	xwrite(&buf[*i], 1);
	(*i)++;
      }
  }
  if(buf[*i] == '|')
    {
      xwrite("(", 1);
    }
  else
    {
      xwrite("() ", 3);
      (*i)--;
    }
}
