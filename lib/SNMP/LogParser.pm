package SNMP::LogParser;

use warnings;
use strict;
# Checked version
$SNMP::LogParser::VERSION = sprintf "1.%04d", q$Revision: 767 $ =~ /(\d+)/g;

=head1 NAME

SNMP::LogParser - An incremental logparser to be used with Net-SNMP

=head1 VERSION

Version $Revision: 765 $

=head1 SYNOPSIS

This is just a wrapper module, please look at 
B<SNMP::LogParser::LogParserDriver> and
at B<logparser>

=head1 AUTHOR

Nito Martinez, C<< <nito at cpan.org> >>

=head1 BUGS

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

Copyright 2007 Nito Martinez, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of SNMP::LogParser
