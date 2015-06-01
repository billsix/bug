// Copyright 2014,2015 - William Emerison Six
//  All rights reserved
//  Distributed under LGPL 2.1 or Apache 2.0

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>

// wrapper to handle ignore errors, and to
// retry reading from the stream
char *xfgets(char *s, int size, FILE *stream)
{
  char * result;
 attemptToRead:
  result = fgets(s, size, stream);
  if(result)
    return result;
  if(feof(stream))
    return result;
  goto attemptToRead;
}


int main(int argc, char** argv)
{
  // either read from stdin and out,
  // or from files
  if(argc != 1 && argc != 3)
    {
      puts("Usage: bug-gscpp , or");
      puts("Usage: bug-gscpp inputfile outputfile");
      exit(1);
    }

  FILE* input;  // the source of the data
  FILE* output; // the output
  // if no args passed, read from stdin and stdout
  if(argc == 1)
    {
      input = stdin;
      output = stdout;
    }
  // otherwise open the input and output files
  else
    {
      // open input file
      {
	char* programName = argv[1];
	input = fopen(programName, "r");
	if(!input)
	  {
	    printf("Error: unable to open input file %s \n",programName);
	    exit(1);
	  }
      }
      // open output file
      {
	char* outputFileName = argv[2];
	output = fopen(outputFileName, "w+");
	if(!output)
	  {
	    printf("Error: unable to open output file %s \n",outputFileName);
	    exit(1);
	  }
      }
    }
  // read the input file into a buffer, translate special characters
  // like "[]{}||" into valid scheme code, write to output file
  {

    const int MAX_LINE = 10000;
    char buf[MAX_LINE]; // buffer, into which to store data from input
    while(xfgets(buf, MAX_LINE, input) != NULL)
      {
	for(int i = 0; buf[i] != 0; i++)
	  {
	    switch(buf[i]){
	    case '[': {
	      static const char text[] = "(lambda ";
	      fputs(text, output);
	      // skip whitespace
	      {
		i++;
		while(isspace(buf[i]))
		  {
		    fputc(buf[i], output);
		    i++;
		  }
	      }
	      if(buf[i] == '|')
		{
		  fputc('(', output);
		}
	      else
		{
		  fputs("() ", output);
		  i--;
		}
	      break;
	    }
	    case '|':
	    case ']':
	      fputc(')', output);
	      break;
	    default:
	      fputc(buf[i], output);
	    }
	  }
	fflush(output);
      }
    fclose(output);
  }
}

