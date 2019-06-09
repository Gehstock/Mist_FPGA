#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
main (int argc, char **argv)
{
unsigned char byte;
int data_len,nb_byte,first_byte;
char *end_file_name;
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

fid_out = fopen(argv[2],"wt");
if (fid_out == NULL)
{
  printf("can't open %s\n",argv[2]);
  fclose(fid_in);
  exit(0);
}

end_file_name = strstr(argv[2],".vhd");
if (end_file_name!=NULL) *end_file_name='\0';

fseek(fid_in,0,SEEK_END);
data_len = ftell(fid_in);
fseek(fid_in,0,SEEK_SET);

fprintf(fid_out,"library ieee;\n");
fprintf(fid_out,"use ieee.std_logic_1164.all,ieee.numeric_std.all;\n\n");
fprintf(fid_out,"entity %s is\n",argv[2]);
fprintf(fid_out,"port (\n");
fprintf(fid_out,"\tclk  : in  std_logic;\n");
fprintf(fid_out,"\taddr : in  std_logic_vector(%d downto 0);\n",(int)ceil(log2((double)data_len))-1);
fprintf(fid_out,"\tdata : out std_logic_vector(7 downto 0)\n");
fprintf(fid_out,");\n");
fprintf(fid_out,"end entity;\n\n");
fprintf(fid_out,"architecture prom of %s is\n",argv[2]);
fprintf(fid_out,"\ttype rom is array(0 to  %d) of std_logic_vector(7 downto 0);\n",data_len-1);
fprintf(fid_out,"\tsignal rom_data: rom := (");

nb_byte = 0;
first_byte = 1;
while(fread(&byte,1,1,fid_in)==1)
{
  if (nb_byte==0) 
  {
    if (first_byte==0) fprintf(fid_out,",");
    fprintf(fid_out,"\n\t\t");
  }
  else
  { fprintf(fid_out,","); }
  first_byte = 0;

  fprintf(fid_out,"X\"%02X\"",byte);
  nb_byte++;
  if (nb_byte==16) nb_byte=0;
}
fprintf(fid_out,");\n");

fprintf(fid_out,"begin\n");
fprintf(fid_out,"process(clk)\n");
fprintf(fid_out,"begin\n");
fprintf(fid_out,"\tif rising_edge(clk) then\n");
fprintf(fid_out,"\t\tdata <= rom_data(to_integer(unsigned(addr)));\n");
fprintf(fid_out,"\tend if;\n");
fprintf(fid_out,"end process;\n");
fprintf(fid_out,"end architecture;\n");

fclose(fid_in);
fclose(fid_out);
}
