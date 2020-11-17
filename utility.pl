#!/usr/bin/perl


$usage = "USAGE: FlexAID_Batch.pl -t target_pdbfile -l ligands -c cleft_pdbfile -b 1 -p 500 -g 500 -a lib_path \n";
$usage .= "\t  -t  target pdbfile\n";
$usage .= "\t  -l  Filename containing the ID of ligand input files\n";
$usage .= "\t  -c  cleft pdbfile\n";
$usage .= "\t  -b  runs\n";
$usage .= "\t  -p  GA Population size \n";
$usage .= "\t  -g  GA number of generations \n";
$usage .= "\t  -a  library path\n";


while(@ARGV){

  $arg = shift @ARGV;
  if($arg eq "-t"){$pdbnam   = shift @ARGV;}
  if($arg eq "-l"){$lignam   = shift @ARGV;}
  if($arg eq "-c"){$clfnam   = shift @ARGV;}
  if($arg eq "-b"){$nruns    = shift @ARGV;}
  if($arg eq "-p"){$numchrom = shift @ARGV;}
  if($arg eq "-g"){$numgener = shift @ARGV;}
  if($arg eq "-a"){$lib_path = shift @ARGV;}
  if($arg eq "-h"){die $usage;}
}


@tmp=split(/\/|\./,$lignam);
$ligid=$tmp[$#tmp-1];
$config_file="CONFIG_".$ligid.".inp";
$ga_file ="ga_inp_".$ligid.".dat";
$logfile ="logfile".$ligid;

write_ga_inp($numchrom,$numgener,$ga_file);

$fl=$lib_path."/FlexAID";
$FlexAID_Command_base = $fl." ".$config_file." ".$ga_file." ";
$flxdih=get_nflxdih($lignam);

write_CONFIG($pdbnam,$lignam,$flxdih,$clfnam,$config_file);

$nrun=0;
$best_cf=999999999999;
$best_run=-1;
$cf=$best_cf;
$runtime=-1;
$run_code=0;

while($nrun < $nruns && $run_code == 0){

  if(!$log{$ligid."_".$nrun}){
    $runlog = $ligid."_".$nrun.".log";
    $FlexAID_Command_line = $FlexAID_Command_base.$ligid."_".$nrun;
    $run_code=system("$FlexAID_Command_line > $runlog");
    if(-e $runlog){
      unlink($ligid."_".$nrun."_INI.pdb");
      unlink($ligid."_".$nrun."_par.res");
      unlink($ligid."_".$nrun.".cad");
      if($run_code==0){
        $runtime=fetch_runtime($runlog);
        $cf=get_cf($ligid."_".$nrun."_0.pdb");
        open(LOG,'>>',$logfile) || die "cannot open $logfile logfile for append\n";
        print LOG $ligid,"_",$nrun," CF ",$cf," TIME ".$runtime,"\n";
        close(LOG);
      }else{
        $bad_smiles=$logfile."_BAD";
        open(BAD,'>>',$bad_smiles) || die "cannot open bad smiles $bad_smiles\n";
        print BAD "$lignam\n";
        close(BAD);
      }
      unlink($runlog);
    }
  }else{
    @tmp=split(/\s+/,$log{$ligid."_".$nrun});
    $cf=$tmp[2];
    $runtime=$tmp[4];
  }
  if($cf < $best_cf){
    $best_cf = $cf;
    $best_run = $nrun;
  }
  $nrun++;
}
$nrun=0;
while($nrun < $nruns){

  if($nrun != $best_run){if(-e $ligid."_".$nrun."_0.pdb"){unlink($ligid."_".$nrun."_0.pdb");}}
  $nrun++;
}


sub get_cf(){

  use strict;
  my $resfile=shift;
  my $line;
  my @tmp;
  my $CF="NA";
  local (*IN);

  open(IN,$resfile) || die "cannot open $resfile to get CF\n";
  while($line = <IN>){

    if($line =~ /^REMARK CF\=/){
      chomp $line;
      @tmp=split(/=/,$line);
      $CF=$tmp[1];
    }
  }
  close(IN);

  return $CF;
}
#-----------------------------------------------------------------------------
sub fetch_runtime(){

  use strict;
  my $log = shift;
  my $line;
  my @tmp;
  local (*IN);

  open(IN,$log) || die "cannot open $log for parsing\n";
  while($line = <IN>){
    if ($line =~ /^GA Computational time/){
      @tmp=split(/\s+/,$line);
    }
  }
  close(IN);
  return $tmp[3];
}
#-----------------------------------------------------------------------------
sub get_nflxdih(){

  use strict;
  my $inplig = shift;
  my $line;
  my $flxdih=0;
  local (*IN);

  open(IN,$inplig) || die "cannot open ligand input file $inplig to get the number of flexible bonds\n";
  while($line = <IN>){
    if($line =~ /^FLEDIH/){
      $flxdih++;
    }
  }
  close(IN);

  return $flxdih;
}
#-----------------------------------------------------------------------------
sub write_CONFIG(){

  use strict;
  my $pdbnam = shift;
  my $lignam = shift;
  my $flxdih = shift;
  my $clfnam = shift;
  my $config_file=shift;
  my $lib_path=shift;
  my $nflexdih=-1;
  my $outstring="";

  $outstring .= "PDBNAM ".$pdbnam."\n";
  $outstring .= "INPLIG ".$lignam."\n";
  $outstring .= "COMPLF VCT\n";
  $outstring .= "RNGOPT LOCCLF ".$clfnam."\n";
  while($nflexdih <= $flxdih){
    $outstring .= "OPTIMZ 9999 - ".$nflexdih."\n";
    $nflexdih++;
  }

  $outstring .= "IMATRX ".$lib_path."/MC_st0r5.2_6.dat\n";
  $outstring .= "PERMEA 0.9\n";
  $outstring .= "VARANG 5.0\n";
  $outstring .= "VARDIH 5.0\n";
  $outstring .= "VARFLX 10.0\n";
  $outstring .= "SLVTYP 40\n";
  $outstring .= "METOPT GA\n";
  $outstring .= "SPACER 0.375\n";
  $outstring .= "VCTPLA R\n";
  $outstring .= "NORMAR\n";
  $outstring .= "NOINTR\n";
  $outstring .= "VINDEX\n";
  $outstring .= "MAXRES 1\n";
  $outstring .= "ENDINP\n";


  open(OUT,">$config_file") || die "cannot open ".$config_file." for write\n";
  print OUT $outstring;
  close(OUT);

  return;
}
#-----------------------------------------------------------------------------
sub write_ga_inp(){

  use strict;
  my $numchrom = shift;
  my $numgener = shift;
  my $ga_file = shift;
  local (*OUT);

  open(OUT,">$ga_file") || die "cannot open ga input file ".$ga_file." for write\n";

  print OUT "NUMCHROM ",$numchrom,"\n";
  print OUT "NUMGENER ",$numgener,"\n";
  print OUT "ADAPTVGA 1\n";
  print OUT "ADAPTKCO 0.95 0.10 0.95 0.10\n";
  print OUT "CROSRATE 0.900\n";
  print OUT "MUTARATE 0.025\n";
  print OUT "POPINIMT RANDOM\n";
  print OUT "FITMODEL PSHARE\n";
  print OUT "SHAREALF 4.00\n";
  print OUT "SHAREPEK 5.00\n";
  print OUT "SHARESCL 10.00\n";
  print OUT "REPMODEL BOOM\n";
  print OUT "BOOMFRAC 1.00\n";
  print OUT "PRINTCHR 1\n";
  print OUT "OUTGENER 1\n";
  close(OUT);

  return;
}
