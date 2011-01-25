package SNMP::LogParser;

use warnings;
use strict;
# Checked version
$SNMP::LogParser::VERSION = sprintf "1.%04d", q$Revision: 10052 $ =~ /(\d+)/g;

=head1 NAME

SNMP::LogParser - An incremental logparser to be used with Net-SNMP

=head1 VERSION

Version $Revision: 10052 $

=head1 SYNOPSIS

This is just a wrapper module, please look at 
B<SNMP::LogParser::LogParserDriver> and
at B<logparser>

B<logparser.pl> [-f configFile] [-p processes] [-s storeFile] [-o propertiesFile] 
                [-l log4perlFile]

Parses a log file

B<logparser.pl> -h

Shows the help man page

B<logparser.pl> -v

shows the version

=head1 DESCRIPTION

The logparser script is supposed to be used from cron and to parse log
files every five minutes starting from the last position read. It should
take in account files that are rotated.

The main configuration comes from the configuration file (see the B<-f>
switch in the B<OPTIONS> section).

The main parsing of any log file should be accomplished by creating
an inherited class from the class B<LogparserDriver> which has methods
for specifying the regular expression, the evalBegin, evalIterate and evalEnd
method.


By default the process is the following:

=head2 SETTING UP THE LOGPARSER

=over 8

=item # Create a subclass of the LogparserDriver.


You need to implement at least define the variable B<pattern> (the regular
expression), and the methods B<evalBegin>, B<evalIterate> (invoked for each
line of the file) and B<evalEnd>.

For an exact description of the methods please see B<LogparserDriver>

=item # Create a configuration file for logparser.


See the B<-f> option. But mainly you need to specify the log file to parse
and the subclass of B<LogparserDriver> to use.

=item # (Optional) Set up the log configuration in B<log4perl.conf>


The default logging entry for logparser uses the tag "logparser" and
the B<LogparserDriver> uses "logparser.LogparserDriver" tag. That is
any subclass of B<LogparserDriver> (including LogparserDriver itself)
uses as the logging tag: "logparser.classname". For more information
about logging please see B<Log::Log4perl>

=item # Set up the logparser to run from cron


This can usually be achieved by creating a cron entry like this (please
check the syntax for your exact *nix system):

$ crontab -e

*/5 * * * * [ -x /usr/bin/logparser ] && /usr/bin/logparser

Please be aware that the logfile should be possible to read as the user
you are running cron from.

=back


=head2 PROCESS OF LOGPARSER

The logparser works as follows

=over 8

=item * Firstly it gets all the options.

More precedence have the command line options, then the options specified in the
configuration file and finally the options defined by default.

=item * Get the saved configuration

All the configuration specified in the B<LogparserDriver> class in the B<savespace>
method are restored from the B<storeFile> including also the seek position of each
logfile parsed.

=item * Create lock file

In this step a lock file is created (see B<lockFile> option). The file is created
with an exclusive lock with the PID (Process Identifier) in it.

If the file exists then it is checked if a process with the recorded process id
exists, if not the file is deleted and the process continued. Otherwise
the process stops assuming that during the next cron invocation the process
will be restored.


=item * Process each log

For each log specified in the configuration file the class specified in the
configuration file is invoked with methods:

=over 8

=item * evalBegin before the line parsing begins

=item * evalIterate for each line of the log. Starting in the position of the last
line parsed.

=item * evalEnd after the parsing ends

=back


=item * Output the properties method

Everything saved during evalBegin, evalIterate or evalEnd in the B<properties>
method of B<LogparserDriver> will be output into the B<propertiesFile> file
of the configuration file (or command line).

=item * The savespace is saved

The B<savespace> variable of the sub class B<LogparserDriver> and the position of the
logfile will be saved.

=item * The lockFile is removed

=back



=head1 OPTIONS

All the command line options override the options in the configuration file.

=head2 COMMAND LINE OPTIONS

=over 8

=item B<-f configuration file>

Indicates the configuration file.
There is no corresponding configuration file option.
The default value is "/etc/logparser/logparser.conf".

=item B<-p number of processes>

Indicates how many concurrent processes should be run in parallel.
The corresponding configuration file option is "processes".

The default value is 1.

This option is not implemented yet

=item B<-s storeFile>

Indicates in which file the %properties hash should be stored.
This has will be stored in a Java properties file in pairs
of key=value pairs

For more information please see the B<LogparserDriver> page.

=item B<-l log4perlFile>

Indicates the configuration file for the Log4Perl configuration file.
The corresponding configuration file option is "log4perlFile".
The default value is "/etc/logparser/log4perl.conf"

=item B<-h>

Shows this help page

=item B<-v>

Shows the version of the script.

=back

=head2 CONFIG FILE OPTIONS

The configuration tag used is "logparser::Default"

=over 8

=item B<log4perl>

This option specifies the log4perl settings for logs.
See the B<Log::Log4perl> documentation.

=item B<log>

Specifies all the logs that should be parsed.
Each "<KEY>" indicates a different log.
The different entries that can be used are:

* log.<KEY>.name: name identifies the log entry. By default the name defaults to "<KEY>".
  Be aware that the name is used to identify the log position. That is if you change the
  name (or the key if you don't define the name) then the log will be parsed from the
  beginning

* log.<KEY>.file: This is the file that should be parsed. This file should always be defined.

* log.<KEY>.driver: This is the class that should be invoked to parse the file specified
above. Please be aware that the class should be a subclass of B<LogparserDriver> class

=back

=head1 EXAMPLE

We will provide here a detailed example on how to parse a particular file:

Assume that we want to get the number of email messages sent and
include the size of these email messages.

An example input line of the log file /var/log/maillog could be:

 Sep  4 11:50:03 localhost sendmail[4091]: k849o3DZ004091: from=root, size=236, class=0, nrcpts=1, msgid=<200609040950.k849o3DZ004091@localhost.localdomain>, relay=root@localhost

The output of the incremental parsing that we want to record should
be registered in a file /var/lib/logparser/logparser.properties with
the values:

 mailMessages=23
 sizeOfMailMessages=52354

The steps that we will follow are:

=over 8

=item * Create a subclass of the LogparserDriver

We need to define the following regular expression to match the log file:

 from=\S+,\s+size=(\d+),

We create a the file /usr/lib/LogparserDriver/MailLog.pm

with the following content:


 package LogparserDriver::ProxyLog;
 
 use warnings;
 use Log::Log4perl;
 use LogparserDriver;
 
 @LogparserDriver::ProxyLog::ISA = ('LogparserDriver');
 
 # Class constructor
 sub new {
  my $class = shift;
  my $self  = $class->SUPER::new();
  bless ($self, $class);
  $self->pattern('from=\S+,\s+size=(\d+),');
  return $self;
 }

 # Everything in savespace will be preserved
 # across different invocations of logparser
 sub evalBegin {
  my $self = shift;
  $self->{savespace}{mailMessages} = 0 if (!defined($self->{savespace}{mailMessages}));
  $self->{savespace}{sizeOfMailMessages} = 0 if (!defined($self->{savespace}{sizeOfMailMessages}));
 }
 
 sub evalIterate {
  my $self = shift;
  my ($line) = @_;
  my $pattern = $self->{pattern};
  if ($line =~ /$pattern/) {
    my ($size) = ($1);
    $self->{savespace}{mailMessages} ++;
    $self->{savespace}{sizeOfMailMessages} += $size;
 }
 }
 
 # Everything saved in the properties hash will be output
 # in /var/lib/logparser/logparser.properties
 # (depending on the log file)
 sub evalEnd {
  my $self = shift;
  $self->{properties} = 
    [ 'mailMessages' => $self->{savespace}{mailMessages},
      'sizeOfMailMessages' => $self->{savespace}{sizeOfMailMessages}
    ];
 }


=item * Create a configuration file for logparser.

We will the following configuration file in /etc/logparser/logparser.conf:

 # storeFile
 # Indicates which file should be used to save %savespace hash
 # By default it is /var/lib/logparser/logparser.store
 storeFile=/var/lib/logparser/logparser.store
 
 # propertiesFile
 # Indicates which file should store the properties
 # generated by the driver
 # By default it is /var/lib/logparser/logparser.properties
 propertiesFile=/var/lib/logparser/logparser.properties
 
 # log to be monitored.
 # For each log you can add several patterns, each one 
 # The work space variable that you must use is $workspace{'name1'}
 # Everything that you save in $savespace{'name1'} will be maintained
 # across sessions.
 log.maillog.name: maillog
 log.maillog.file: /var/log/maillog
 log.maillog.driver: LogparserDriver


=item * Set up the logparser to run from cron

 */5 * * * * [ -x /usr/bin/logparser ] && /usr/bin/logparser

=back

=head1 REQUIREMENTS and LIMITATIONS

=head1 INSTALLATION

B<Required Perl packages>

The perl packages installed for this script are:

=over 8

=item * Storable

=item * Config-Find-0.15

=item * File-Temp-0.14

=item * File-HomeDir-0.05

=item * File-Which-0.05

=item * Config-Properties-Simple-0.09

=item * Proc::ProcessTable

=item * Log::Dispatch::FileRotate

=back

=head1 BUGS

=head1 AUTHOR

Nito Martinez, C<< <nito at Qindel dot ES> >>

=head1 BUGS

=over 8

=item * When following situation ocurrs some entry lines might not be parsed

1) When the size of the log file during parse n is greater than the size of 
the log during parse n+1 and the log has been rotated in the mean time.


=item * When the machine reboots and the lock file is not stored in a tempfs
        it might happen that another process has started with the pid stored
        in the lock file. The workaround is to store the lock file in /tmp

=back


Please report any bugs or feature requests to
C<bug-netsnmp-logparser at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SNMP-LogParser>.
I will be notified, and then you will automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SNMP::LogParser

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SNMP-LogParser>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SNMP-LogParser>

=item * RT: CPAN request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SNMP-LogParser>

=item * Search CPAN

L<http://search.cpan.org/dist/SNMP-LogParser>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 by Qindel Formacion y Servicios SL, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of SNMP::LogParser
