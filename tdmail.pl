#!/usr/bin/perl -w

###
# tdmail.pl
# version: 0.3
###
# pavel skvortsov <pavel.skvortsov@gmail.com>, ufk29.ofk26
# 2007
###

#use strict;

use POSIX qw(strftime);
use Net::FTP;
use File::Basename;
use File::Copy;         # copy(), move()
use File::Path;         # mkpath(), rmtree()
use File::stat;         # stat()

###
### ������������� ������������
###

my $config = "tdmail.conf"; # ��� ����������������� ����� �� ���������
my $ai = 0;                 # ������� ���������� ��������� ������

foreach (@ARGV) {
  if ($ARGV[$ai] eq "-c") {
    $config = "$ARGV[$ai+1]"; last;
  }
  $ai++;
} 
require "$config";

###
### ������ ���������
###

my $VER = "0.3b";
my $DATE = "04.01.2007";
my $TITLE = "\"summer in may\"";

###
### ��������� ��������� ������
###

my ($listing, $keep_files, $silent_mode);
foreach (@ARGV) {
  if ($_ eq '-h') { print out("version"); out("author"); out("help"); }
  if ($_ eq '-list') { $listing = 1; }
  if ($_ eq '-nodel') { $keep_files = 1; }
  if ($_ eq '-nosignal') { $silent_mode = 1; }
}
undef if $listing == NULL; undef if $keep_files == NULL; undef if $silent_mode == NULL;

###
### ������� ����������� ����������
###

# ����� ������, ������� ���������� ������� ���������� (regexp)
#$ascii_mask = qr/(\.txt)|(\.v$ofk)|(\.i$ofk)|(\.r$ofk)|(\.s$ofk)|(pismo)/is;
my $ascii_mask = qr/(\.txt)|(\.r$ofk)|(\.s$ofk)|(pismo)/is;

# �������������� ��������/��������� ����� �� ftp/�������� (��� ������� ������)
%replace = (
  'es_out' => 'es_in',
  'outgoing' => 'pm_in',
  'rki_out' => 'rki_in',

  'es_in' => 'es_out',
  'incoming' => 'pm_out',
  'rki_in' => 'rki_out'
);

#%path = (
#);

###
### ������ ������
###

my $NAME = out("version");
open(LOG, ">>$log_file") or die "! Can't open file $log_file: $!";

print "----------\n";
print LOG "----------\n";

log_this("$NAME started!\n");

# ���� ������������ �������������� ���������������� ����
if ($config ne 'tdmail.conf') { log_this("Using alternative configuration: $config.\n"); }

# ���� ����� �������� '-list' � ��������� ������ (������ ������ ������)
if (($listing) and ($listing == 1)) { log_this("We will get file listing only.\n"); }

# ���� ����� �������� '-nosignal' � ��������� ������ (��������� �����������)
if (($silent_mode) and ($silent_mode == 1)) { log_this("Notify function disabled.\n"); }

# ����������� � �������
ftp_connect();

$, = "\n";  # ����������� ��� ������ ������� �� �����

# ��������� ������ ���������� �� ������� � ������
#log_this("Getting directory listing...\n");
@remotedirs = $ftp->ls(); # or die "! Cannot get a directory listing ", $ftp->message;
#~ print $ftp->message;

#
# ��������� � ����������� ������ � ����� ($root_dir)
#

# ����� ���� ����������, ������� ����� ����������, ��� ������
# ������ ������ � ����������
@remotedirs_in = grep (!/(^in)|(\_in)|(avp)|(drweb)|(bank)|(sed_out)/, @remotedirs);
#@remotedirs_in = grep (!/(^in)|(\_in)|(avp)|(drweb)|(sed_out)/, @remotedirs);

log_this("* RECEIVING\n");

#my %files_mdtm; my @just_one_file;

chdir("$mail_dir");
foreach my $localdir (@remotedirs_in) {
  local $, = ", ";  # ����������� ��������� �������
  
  log_this("\\$localdir\n");
  $ftp->cwd($localdir);
  my @files = $ftp->ls();

  chdir("$localdir");

  if ((($listing) and ($listing != 1)) or (!$listing)) {
    # ��� ��������� ������������ ��� �� ��������� ������ ������� ����
    # if ($localdir eq 'bank') {
      # if (get_bank_files(@files) eq "0") {  # ���� ����� ������ ������
        # foreach my $file (@files) {
          # # ����������
          # my $filesize = round($ftp->size($file));
          # log_this("$file ($filesize KB) -> $mail_dir\\$localdir\\$file\n");
          # set_transfer_mode($file);
          # $ftp->get($file, "$mail_dir\\$localdir\\$file");
          # $ftp->message;
          
          # # ����������� � �����
          # my $path = "$root_dir\\$localdir\\$today_dir";
          # if (!-d $path) { log_this("Making path $path\n"); mkpath($path); }
          
          # if (!-f "$path\\$file") {
            # log_this("$file -> $path\\$file\n");
            # copy("$file", "$path\\$file") or die_log("! Copy failed: $!");
          # } else {
            # log_this("File $path\\$file already exists\n");
          # }
        # }
      # } else { print "1111111111111111111\n" . get_bank_files(@files) . "\n"; }
    # } else {
      foreach my $file (@files) {
        my $filesize = round($ftp->size($file));
        #log_this("$host\\$localdir\\$file ($filesize KB) -> $mail_dir\\$localdir\\$file\n");
        log_this("$file ($filesize KB) -> $mail_dir\\$localdir\\$file\n");
#      $files_mdtm->{"$file"} = "$ftp->mdtm($file)"; # ���������� �������� � ���
        set_transfer_mode($file);
        $ftp->get($file, "$mail_dir\\$localdir\\$file");
        $ftp->message;
        
#      $just_one_file->[0] = "$file";
        #my $sb = stat("$mail_dir\\$localdir\\$file");
        #my $fileowner = $sb->uid;
#      my $fileowner = (stat("$mail_dir\\$localdir\\$file"))[4];
#      log_this("$fileowner");
        
#      utime $ftp->mdtm($file), $ftp->mdtm($file), @just_one_file;
        
        my $path = "$root_dir\\$replace{$localdir}\\$today_dir";
        if (!-d $path) {
          #log_this("Making path $path\n");
          mkpath($path) or die_log("! mkpath(\"$path\") failed: $!");
        }
        
        if (!-f "$path\\$file") {
          #log_this("$mail_dir\\$localdir\\$file -> $path\\$file\n");
          log_this("$file -> $path\\$file\n");
          copy("$file", "$path\\$file") or die_log("! Copy failed: $!");
        } else {
          log_this("File $path\\$file already exists\n");
        }
        
        # ����������� �������
        if (($file =~ /.+\.r$ofk/i) or ($file =~ /14\d{2}[\d\w]\d$ofk\.arj/i)) {
          if (!-f "$report_dir\\$file") {
            log_this("$file -> $report_dir\\$file\n");
            copy("$file", "$report_dir\\$file") or die_log("! Copy failed: $!");
          } else {
            log_this("File $report_dir\\$file already exists\n");
          }
#        } elsif ($file =~ /\d{4}[\d\w]\d$ofk\.arj/i) {
#        # ����������� ��������� �� ������
          
        }
        
        if ((($keep_files) and ($keep_files != 1)) or (!$keep_files)) {
          $ftp->delete($file);  # ���� � ��������� ������ �� ������ �������� -nodel,
          $ftp->message;        # ����� � ftp ���������; ����� - ���.
        }
      }
    # }

  } else {
    print @files; print "\n";
  }

  # ������������ � �������� ������ :-)
  if ((($silent_mode) and ($silent_mode != 1)) or (!$silent_mode)) {
    my $signal_string = "� ���������� \"T:\\$localdir\" ��������� ����� �����!";
    my $signal_pc;
    if ($localdir eq 'es_out') {
      $signal_pc = "buh-1";
      if ($#files != -1) { system("net send $signal_pc $signal_string"); }
      $signal_pc = "buh-6";
      if ($#files != -1) { system("net send $signal_pc $signal_string"); }
    } elsif ($localdir eq 'outgoing') {
      $signal_pc = "reception";
      if ($#files != -1) { system("net send $signal_pc $signal_string"); }
    } elsif ($localdir eq 'rki_out') {
      $signal_pc = "ito";
      if ($#files != -1) { system("net send $signal_pc $signal_string"); }
    }
  }
  
  $ftp->cdup();
  chdir("..");
}

#
# �������� � ����������� ������ � ����� ($root_dir)
#

@remotedirs_out = grep (!/(^out)|(\_out)|(avp)|(drweb)|(bank)/, @remotedirs);

log_this("* SENDING\n");

chdir("$mail_dir");
foreach my $localdir (@remotedirs_out) {
  #print "* $localdir\n";
  log_this("\\$localdir\n");
  #~ foreach my $mask (%mask_in) {
    #~ my @files = get_dir_contents($mask_in{$mask});
    my @files = get_dir_contents($localdir);
    print @files; if ($#files != -1) { print "\n"; }
    if ($#files != -1) {
      chdir("$localdir");
      # ����������� � ���������� ��� ��������
      #$ftp->cwd($remotedir);

      my $path = "$root_dir\\$replace{$localdir}\\$today_dir";
      if (!-d $path) {
        #log_this("Making path $path\n");
        mkpath($path) or die_log("! mkpath(\"$path\") failed: $!");
      }

      foreach my $file (@files) {
        my $sb = stat($file);
        my $filesize = round($sb->size);
        #log_this("$mail_dir\\$localdir\\$file -> $host\\$localdir\\$file ($filesize KB)\n");
        log_this("$file -> $host\\$localdir\\$file ($filesize KB)\n");
        set_transfer_mode($file);
        #$ftp->put("$file", "//$localdir//$file") or die "! Cannot upload file: $!", $ftp->message;
        $ftp->put("$file", "\/$localdir\/$file") or die "! Cannot upload file: $!", $ftp->message;

        #log_this("$mail_dir\\$localdir\\$file -> $path\\$file\n");
        log_this("$file -> $path\\$file\n");
        move("$file", "$path\\$file") or die "! Move failed: $!";
      }
      $ftp->cdup();
      chdir("..");
    }
  #~ }
}

# ���������� �� �������
ftp_disconnect();

log_this("$NAME stopped!\n");

# �������� ���-�����
close(LOG) or die "! Can't close file $log_file: $!";

# �����!
exit 0;

# ====================================
# ���������������
# ====================================

$SIG{__DIE__} = sub {
    #print "using own die handler\n";
  # my $string = shift;
  # my $datetime = datetime_();
  # print LOG "$datetime  ! $string\n";
  # close(LOG);
  # die "$string";
};

# ====================================
# ������� � ���������
# ====================================

sub ftp_connect {
  #datetime(1); print "  Starting FTP connection to $host...\n";
  log_this("Starting FTP connection to $host...\n");
  $ftp = Net::FTP->new($host, Debug => 0)
      #or die "! Cannot connect to $host: $@";
      or die_log("Cannot connect to $host: $@");
  #print $ftp->message;
  
  $ftp->login($userlogin, $userpassw)
      #or die "! Cannot login ", $ftp->message;
      or die_log("! Cannot login ", $ftp->message);
  #print $ftp->message;
  log_this($ftp->message);
}

sub ftp_disconnect {
  # datetime(1); print "  Disconnecting...\n";
  log_this("Disconnecting...\n");
  $ftp->quit();
  #print $ftp->message;
  log_this($ftp->message);
  #datetime(1); print "  Logout.\n";
}

# ��������� ������������ ����������� ������
sub get_bank_files {
  my @remote_files = shift;
  my @local_files = get_dir_contents("$mail_dir\\bank");
  print @remote_files; print @local_files;
  my $value = "";

  foreach my $r_file (@remote_files) {
    foreach my $l_file (@local_files) {
      if (($r_file =~ /.+\.dbf/i) and ($l_file =~ /.+\.dbf/i)) {
        print "$r_file - $l_file - fuck you!\n";
        if ($r_file eq $l_file) { # ���� ����� ������ ���������
          print "aaa\n"; $value = "1"; last; last;
        } else {
          print "bbb\n"; $value = "0"; last; last;
        }
      }
    }
  }
  return $value;
}

sub get_dir_contents {
  $dir = shift;
  opendir(DIR, $dir) or die "! Cannot open dir $dir: $!";
  @dirlist = grep(!/^\.+/, readdir(DIR));   # �������� ������ ����������
  #~ @dirlist = grep { !/^\./ && -d "$_" } readdir(DIR);
  closedir(DIR);
  return @dirlist;
}

# ��������� (����������) ������ �� ��������� �� ������ ������� ���������� �� ftp
# ($ftp->cwd($dir))
#   �������� 1 - ������� �� ����� � ������� (0, 1);
#   �������� 2 - ���������� �� ������� � ���������.
sub get_files {
  my $delete_file = shift;
  my $_dir = shift;
  my @files = $ftp->ls();
  print "\n";
  foreach $file (@files) {
    $filesize = round($ftp->size($file));
    #datetime(1); print "  Getting file $file ($filesize KB) to $mail_dir\\$_dir\n";
    #log_this("Getting file $file ($filesize KB) to $mail_dir\\$_dir\n");
    log_this("$host\\$_dir\\$file ($filesize KB) -> $mail_dir\\$_dir\\$file\n");
    set_transfer_mode($file);
    $ftp->get($file, "$mail_dir\\$_dir\\$file");
    $ftp->message;
    if ($delete_file == 1) {    # ���� � �������� ��������� ��� ������ ������� �������� "1",
      $ftp->delete($file);      # ����� � ftp ���������; ����� - ���.
      $ftp->message;
    }
  }
}

# ��������� ������ �������� ������ � ����������� �� ����������
# (binary, ascii)
sub set_transfer_mode {
  $ifile = shift;
    if ($ifile =~ $ascii_mask) {
      $ftp->ascii; #print "ascii\n";
    } else {
      $ftp->binary; #print "binary\n";
    }
}

# ��������������: ����� -> ������; ���������� �� �������
sub round {
  $number = shift;
  $number = $number / 1024;
  $rounded = sprintf("%.1f", $number);
  return $rounded;
}

# �������������� ����: dd.mm.yyyy -> yyyymmdd
sub version_date_grep {
  my ($DD, $MM, $YY) = split(/\./, $DATE);
  return "$YY$MM$DD";
}

sub out {
  my $string = shift;
  if ($string =~ /version/i) {
    #~ print "$0 v$VER-$DATE";
    return basename("$0") . " $TITLE v$VER-" . version_date_grep();
  } elsif ($string =~ /help/i) {
    print "\n- See doc\\README.html for all useful information.\n";
    exit 0;
  } elsif ($string =~ /author/i) {
    print "\n(c)\t2007 pavel skvortsov <pavel.skvortsov\@gmail.com>\n\tufk29.ofk26\n";
  }
}

sub datetime {
  my $dateonly = shift;
  #$now_string = strftime "%a %b %e %H:%M:%S %Y", localtime;
  my $now_string = strftime("%d.%m.%Y %H:%M:%S", localtime(time));
  print $now_string;
  if ($dateonly != 1) {
    print "  ";
  }
}

sub datetime_ {
  my $now_string = strftime("%d.%m.%Y %H:%M:%S", localtime(time));
  return $now_string;
}

# ��������� ������ �� ����� � ��������� � ���-����
sub log_this {
#  shift;
#  if ($_) {
#    my $string = $_;
    my $string = shift;
    my $datetime = datetime_();
    print LOG "$datetime  $string";
    print STDOUT "$datetime  $string";
#  } elsif (@_) {
#  }
}

# �������� ������� ���������, �������������� ������ ���������� �� ������ � ���-����
sub die_log {
  my $string = shift;
  my $datetime = datetime_();
  print LOG "$datetime  ! $string\n";
  # print STDOUT "$datetime  ! $string\n";
  # log_this("$string\n");
  close(LOG);
  die "$string";
  # die;
}
