#include "stdio.h"
#include "stdlib.h"
main (int argc, char **argv)
{
unsigned char byte;
FILE *fid_in,*fid_out;

if (argc != 3)
{
  printf("Syntax : %s file_in file_out\n",argv[0]);
  exit(0);
}

fid_in = fopen(argv[1],"rb");
if (fid_in == NULL)
{
  printf("can't open %s\n",argv[1]);
  exit(0);
}

fid_out = fopen(argv[2],"wb");
if (fid_out == NULL)
{
  printf("can't open %s\n",argv[2]);
  fclose(fid_in);
  exit(0);
}

while (fread(&byte,1,1,fid_in)==1)
{
 fwrite(&byte,1,1,fid_out);
 fwrite(&byte,1,1,fid_out);
}

fclose(fid_in);
fclose(fid_out);
}
