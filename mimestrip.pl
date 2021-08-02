#!/usr/bin/env perl
#
# Convert an e-mail message to a single word-wrapped text part
#
# Usage:
#
#   perl mimestrip.pl < message
#
# This script takes a text/rfc822 message, strips out all but the
# first plain-text part (or converting the first HTML part to plain
# text if there is no plain-text part), and word-wraps the plain-text
# part.  The original message is read from stdin and the modified
# message is written to stdout.
#
#
# Copyright 2021 Tristan Miller
#
# mimestrip is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# mimestrip is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with mimestrip.  If not, see <https://www.gnu.org/licenses/>.


use warnings;
use strict;

use Mail::Message;
use Text::Autoformat;
use Mail::Message::Convert::HtmlFormatText 3.011;

die "Usage: $0 < message\n"
    unless @ARGV==0;

my $msg;
my $part = undef;

$msg = Mail::Message->read(\*STDIN);

if ( $msg->isMultipart ) {

    # Find the first text part (or if no text part exists,
    # the first HTML part) and delete all other parts
    foreach my $p ( $msg->parts ) {
        if ((not defined $part)
            && ($p->contentType eq 'text/plain'
                || $p->contentType eq 'text/html')) {
            $part = $p;
        }
        elsif (defined $part
               && $part->contentType eq 'text/html'
               && $p->contentType eq 'text/plain') {
            $part->delete;
            $part=$p;
        }
        else {
            $p->delete;
        }
    }
}

rebuildMessage($msg);
$part = ($msg->parts)[0];

# Convert any HTML to text, then remove any HTML part
if ($part->contentType eq 'text/html') {
    rebuildMessage($msg);
    $msg = $msg->rebuild(
        keep_message_id => 1,
        extra_rules => [
            'textAlternativeForHtml',
            'removeHtmlAlternativeToText',
        ],
        textAlternativeForHtml => { leftmargin => 0 },
        );
}
rebuildMessage($msg);

# Replace the message body with wrapped text
my $wrapped_data = autoformat($msg->body->decoded, {all => 1});
my $body = Mail::Message::Body->new(
    based_on => $msg->body,
    data => $wrapped_data,
    message => $msg,
    );
$msg->storeBody($body);

print $msg->string();

sub rebuildMessage {
    $_[0] = $_[0]->rebuild(
        keep_message_id => 1,
        extra_rules => [ 'removeDeletedParts']
        );
}
