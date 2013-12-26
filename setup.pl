#!/usr/bin/perl -w

###
# setup.pl
# version: 0.1
# setup utility for tdmail.pl v0.3
###
# pavel skvortsov <pavel.skvortsov@gmail.com>, ufk29.ofk26
# 2007
###

use strict;
use encoding 'cp1251';

use POSIX qw(strftime);
# use Net::FTP;
use File::Basename;
# use File::Copy;         # copy(), move()
# use File::Path;         # mkpath(), rmtree()
# use File::stat;         # stat()

my $VER = "0.1a";
my $DATE = "08.02.2007";
my $TITLE = "";

my $log_file = "setup.log";

my $NAME = out("version");

# закрытие лог-файла
open(LOG, ">>$log_file") or die "! Can't open file $log_file: $!";

print "----------\n";
print LOG "----------\n";

log_this("$NAME started!\n");

log_this("$NAME stopped!\n");

# закрытие лог-файла
close(LOG) or die "! Can't close file $log_file: $!";

exit 0;

# ====================================
# функции
# ====================================

sub datetime {
  my $now_string = strftime("%d.%m.%Y %H:%M:%S", localtime(time));
  return $now_string;
}

# выведение строки на экран и занесение в лог-файл
sub log_this {
    my $string = shift;
    my $datetime = datetime();
    print LOG "$datetime  $string";
    print STDOUT "$datetime  $string";
}

# преобразование даты: dd.mm.yyyy -> yyyymmdd
sub version_date_grep {
  my ($DD, $MM, $YY) = split(/\./, $DATE);
  return "$YY$MM$DD";
}

sub out {
  my $string = shift;
  if ($string =~ /version/i) {
    #return basename("$0") . " $TITLE v$VER-" . version_date_grep();
    return basename("$0") . " v$VER-" . version_date_grep();
  } elsif ($string =~ /help/i) {
    print "\n- See doc\\README.html for all useful information.\n";
    exit 0;
  } elsif ($string =~ /author/i) {
    print "\n(c)\t2007 pavel skvortsov <pavel.skvortsov\@gmail.com>\n\tufk29.ofk26\n";
  }
}

