// Copyright 2014-2016 - William Emerison Six
//  All rights reserved
//  Distributed under LGPL 2.1 or Apache 2.0

#include <stdio.h>
#include <stdlib.h>

#include <sys/types.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

/*
 *  bug-gsi:
 *     Provides an interactive Gambit C scheme environment
 *     with the syntax extensions of bug-gscpp.
 *
 */

int main(int argc, char** argv)
{
  int pipe_from_buggscpp_to_gsi[2];
  // create a communication channel between the
  // output of buggscpp and the input of gsi
  {
    pipe(pipe_from_buggscpp_to_gsi);
  }

  pid_t pid;
  if(pid = fork(),
     pid == -1)
    {
      perror( "fork error: ");
      exit( 1);
    }


  if( pid != 0)
    {
      // In the parent process, take the write end of the pipe,
      // and copy it into stdout.

      while ((dup2(pipe_from_buggscpp_to_gsi[1], STDOUT_FILENO) == -1) && (errno == EINTR)) {}
      // once that is done, there is no more need of the
      // original copy
      close(pipe_from_buggscpp_to_gsi[0]);
      // we never needed the read end in the parent process
      close(pipe_from_buggscpp_to_gsi[1]);

      // executer bug-gscpp
      int returnCode = execlp("bug-gscpp","bug-gscpp",NULL);
    }
  else
    {
      // In the child process, take the read end of the pipe,
      // and copy it into stdin.

      while ((dup2(pipe_from_buggscpp_to_gsi[0], STDIN_FILENO) == -1) && (errno == EINTR)) {}
      // once that is done, there is no more need of the
      // original copy
      close(pipe_from_buggscpp_to_gsi[0]);
      // we never needed the write end in the parent process
      close(pipe_from_buggscpp_to_gsi[1]);

      // execute gsi, using stdin and stdout
      int returnCode = execlp("gsi","gsi","-:d-,tE",NULL);
    }
  return 0;
}
