package Wx::Perl::ListCtrl;

=head1 NAME

Wx::Perl::ListCtrl - a sensible API for Wx::ListCtrl

=head1 SYNOPSIS

    use Wx::Perl::ListCtrl;

    my $lc = Wx::Perl::ListCtrl->new( $parent, -1 );

    # add columns...

    # get/set item text easily
    $lc->InsertItem( 0, 'dummy' );
    $lc->SetItemText( 0, 0, 'row 0, col 0' );
    $lc->SetItemText( 0, 1, 'row 0, col 1' );
    $lc->GetItemText( 0, 1 ) # 'row 0, col 1'

    # use structured data, not plain integers
    $lc->SetItemData( 0, { complex =>1, data => 2 } );
    my $data = $lc->GetItemData( 0 );

    # sensible way of getting the selection
    my $selection = $lc->GetSelection;   # single selection
    my @selections = $lc->GetSelections; # multiple selections

=head1 DESCRIPTION

The C<Wx::ListCtrl> API is terrible. This module goes further than
C<Wx::ListView> in providing a sane api for C<Wx::ListCtrl>.

B<This module is not a drop-in replacement for C<Wx::ListCtrl> and
C<Wx::ListView> >.

C<Wx::Perl::ListCtrl> derives from C<Wx::ListView>, however some of
C<Wx::ListView/Wx::ListCtrl> methods are overridden with more sensible
implementations.

=cut

use strict;

our $VERSION = '0.01';

use Wx qw(:listctrl);
use base 'Wx::ListView';

sub carp { require Carp; goto &Carp::carp; }

=head1 METHODS

=head2 GetSelection

=cut

sub GetSelection {
    my $self = shift;

    carp( "GetSelection must be used on single selection Wx::Perl::ListCtrl" )
      unless $self->GetWindowStyleFlag & wxLC_SINGLE_SEL;

    return $self->GetFirstSelected;
}

=head2 GetSelections

=cut

sub GetSelections {
    my $self = shift;

    carp( "GetSelections must be used on multi selection Wx::Perl::ListCtrl" )
      if $self->GetWindowStyleFlag & wxLC_SINGLE_SEL;

    my $selection = $self->GetFirstSelected;

    return if $selection == -1;

    my @selections = ( $selection );

    while( ( $selection = $self->GetNextSelected( $selection ) ) != -1 ) {
        push @selections, $selection;
    }

    return @selections;
}

=head2 GetItemText

=cut

sub GetItemText {
    my( $self, $item, $col ) = @_; $col ||= 0;

    return $self->SUPER::GetItemText( $item ) if $col == 0;
    my $it = $self->GetItem( $item, $col );

    return $it ? $it->GetText : '';
}

=head2 SetItemtext

=cut

*SetItemText = \&Wx::ListCtrl::SetItemString;

=head2 SetItemData

=cut

sub SetItemData {
    my( $self, $item, $data ) = @_;
    my $stash = $self->{_wx_data} ||= {};
    my $idx = $self->SUPER::GetItemData( $item ) || 0;

    unless( defined $data ) {
        delete $stash->{$idx};
        return;
    }

    unless( $idx ) {
        my $count = $self->{_wx_count} || 0;
        die "FIXME"
          if $count >= ( $idx = ++$self->{_wx_count} ); # need to think
    }

    $stash->{$idx} = $data;

    $self->SUPER::SetItemData( $item, $idx );
}

=head2 GetItemData

=cut

sub GetItemData {
    my( $self, $item ) = @_;
    my $stash = $self->{_wx_data};
    return unless $stash;

    return $stash->{$self->SUPER::GetItemData( $item ) || 0};
}

# overridden to correctly handle the custom item data,
# they do not change user-visible behaviour

sub DeleteAllItems {
    my $self = shift;
    my $ret = $self->SUPER::DeleteAllItems;

    if( $ret ) {
        delete $self->{_wx_data};
        delete $self->{_wx_count};
    }

    return $ret;
}

sub ClearAll {
    my $self = shift;

    $self->SUPER::ClearAll;

    delete $self->{_wx_data};
    delete $self->{_wx_count};
}

sub DeleteItem {
    my( $self, $item ) = @_;
    my $key = $self->SUPER::GetItemData( $item );
    my $ret = $self->SUPER::DeleteItem( $item );

    delete $self->{_wx_data}{$key} if $ret;

    return $ret;
}

1;

__END__

=head1 BUGS

Calling C<SetItemData> too may times will crash after about 2^31
per-object calls (with 32 bit integers).

=head1 AUTHOR

Mattia Barbon <mbarbon@cpan.org>

=head1 LICENSE

Copyright (c) 2005 Mattia Barbon <mbarbon@cpan.org>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself
