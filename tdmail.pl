#!/usr/bin/perl -w

###
# tdmail.pl
# version: 0.3
###
# pavel skvortsov <pavel.skvortsov@gmail.com>, ufk29.ofk26
# 2007
###

#use strict;
use encoding 'cp1251';

use POSIX qw(strftime);
use Net::FTP;
use File::Basename;
use File::Copy;         # copy(), move()
use File::Path;         # mkpath(), rmtree()
use File::stat;         # stat()

###
### инициализация конфигурации
###

my $config = "tdmail.conf"; # имя конфигурационного файла по умолчанию
my $ai = 0;                 # счетчик параметров командной строки

foreach (@ARGV) {
  if ($ARGV[$ai] eq "-c") {
    $config = "$ARGV[$ai+1]"; last;
  }
  $ai++;
} 
require "$config";

###
### версия программы
###

my $VER = "0.3b";
my $DATE = "04.01.2007";
my $TITLE = "\"summer in may\"";

###
### параметры командной строки
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
### жесткое определение переменных
###

# маски файлов, которые необходимо считать текстовыми (regexp)
#$ascii_mask = qr/(\.txt)|(\.v$ofk)|(\.i$ofk)|(\.r$ofk)|(\.s$ofk)|(pismo)/is;
my $ascii_mask = qr/(\.txt)|(\.r$ofk)|(\.s$ofk)|(pismo)/is;

# переназначение входящих/исходящих путей на ftp/локально (для ведения архива)
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
### начало работы
###

my $NAME = out("version");
open(LOG, ">>$log_file") or die "! Can't open file $log_file: $!";

print "----------\n";
print LOG "----------\n";

log_this("$NAME started!\n");

# если используется альтернативный конфигурационный файл
if ($config ne 'tdmail.conf') { log_this("Using alternative configuration: $config.\n"); }

# если задан параметр '-list' в командной строке (только список файлов)
if (($listing) and ($listing == 1)) { log_this("We will get file listing only.\n"); }

# если задан параметр '-nosignal' в командной строке (отключить оповещение)
if (($silent_mode) and ($silent_mode == 1)) { log_this("Notify function disabled.\n"); }

# подключение к серверу
ftp_connect();

$, = "\n";  # разделитель при выводе массива на экран

# получение списка директорий на сервере в массив
#log_this("Getting directory listing...\n");
@remotedirs = $ftp->ls(); # or die "! Cannot get a directory listing ", $ftp->message;
#~ print $ftp->message;

#
# получение и копирование файлов в архив ($root_dir)
#

# маски имен директорий, которые нужно пропускать, при выводе
# списка файлов и скачивании
@remotedirs_in = grep (!/(^in)|(\_in)|(avp)|(drweb)|(bank)|(sed_out)/, @remotedirs);
#@remotedirs_in = grep (!/(^in)|(\_in)|(avp)|(drweb)|(sed_out)/, @remotedirs);

log_this("* RECEIVING\n");

#my %files_mdtm; my @just_one_file;

chdir("$mail_dir");
foreach my $localdir (@remotedirs_in) {
  local $, = ", ";  # разделитель элементов массива
  
  log_this("\\$localdir\n");
  $ftp->cwd($localdir);
  my @files = $ftp->ls();

  chdir("$localdir");

  if ((($listing) and ($listing != 1)) or (!$listing)) {
    # для получения справочников БИК РФ получение файлов немного иное
    # if ($localdir eq 'bank') {
      # if (get_bank_files(@files) eq "0") {  # если имена файлов разные
        # foreach my $file (@files) {
          # # скачивание
          # my $filesize = round($ftp->size($file));
          # log_this("$file ($filesize KB) -> $mail_dir\\$localdir\\$file\n");
          # set_transfer_mode($file);
          # $ftp->get($file, "$mail_dir\\$localdir\\$file");
          # $ftp->message;
          
          # # копирование в архив
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
#      $files_mdtm->{"$file"} = "$ftp->mdtm($file)"; # добавление значений в хэш
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
        
        # копирование отчетов
        if (($file =~ /.+\.r$ofk/i) or ($file =~ /14\d{2}[\d\w]\d$ofk\.arj/i)) {
          if (!-f "$report_dir\\$file") {
            log_this("$file -> $report_dir\\$file\n");
            copy("$file", "$report_dir\\$file") or die_log("! Copy failed: $!");
          } else {
            log_this("File $report_dir\\$file already exists\n");
          }
#        } elsif ($file =~ /\d{4}[\d\w]\d$ofk\.arj/i) {
#        # копирование квитанции на заявку
          
        }
        
        if ((($keep_files) and ($keep_files != 1)) or (!$keep_files)) {
          $ftp->delete($file);  # если в командной строке не указан параметр -nodel,
          $ftp->message;        # файлы с ftp удаляются; иначе - нет.
        }
      }
    # }

  } else {
    print @files; print "\n";
  }

  # сигнализация о принятых файлах :-)
  if ((($silent_mode) and ($silent_mode != 1)) or (!$silent_mode)) {
    my $signal_string = "В директории \"T:\\$localdir\" появились новые файлы!";
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
# отправка и копирование файлов в архив ($root_dir)
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
      # перемещение в директорию для загрузки
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

# отключение от сервера
ftp_disconnect();

log_this("$NAME stopped!\n");

# закрытие лог-файла
close(LOG) or die "! Can't close file $log_file: $!";

# выход!
exit 0;

# ====================================
# переопределения
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
# функции и процедуры
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

# получение ОБНОВЛЕННОГО справочника банков
sub get_bank_files {
  my @remote_files = shift;
  my @local_files = get_dir_contents("$mail_dir\\bank");
  print @remote_files; print @local_files;
  my $value = "";

  foreach my $r_file (@remote_files) {
    foreach my $l_file (@local_files) {
      if (($r_file =~ /.+\.dbf/i) and ($l_file =~ /.+\.dbf/i)) {
        print "$r_file - $l_file - fuck you!\n";
        if ($r_file eq $l_file) { # если имена файлов одинаковы
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
  @dirlist = grep(!/^\.+/, readdir(DIR));   # получаем список директорий
  #~ @dirlist = grep { !/^\./ && -d "$_" } readdir(DIR);
  closedir(DIR);
  return @dirlist;
}

# получение (скачивание) файлов из указанной до вызова функции директории на ftp
# ($ftp->cwd($dir))
#   параметр 1 - удалять ли файлы с сервера (0, 1);
#   параметр 2 - директория на сервере и локальная.
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
    if ($delete_file == 1) {    # если в качестве параметра при вызове функции передана "1",
      $ftp->delete($file);      # файлы с ftp удаляются; иначе - нет.
      $ftp->message;
    }
  }
}

# установка режима передачи файлов в зависимости от расширения
# (binary, ascii)
sub set_transfer_mode {
  $ifile = shift;
    if ($ifile =~ $ascii_mask) {
      $ftp->ascii; #print "ascii\n";
    } else {
      $ftp->binary; #print "binary\n";
    }
}

# преобразование: Байты -> кБайты; округление до десятых
sub round {
  $number = shift;
  $number = $number / 1024;
  $rounded = sprintf("%.1f", $number);
  return $rounded;
}

# преобразование даты: dd.mm.yyyy -> yyyymmdd
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

# выведение строки на экран и занесение в лог-файл
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

# аварийно закрыть программу, предварительно занеся информацию об ошибке в лог-файл
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
